extends Node
##
## SaveSystem — JSON IO, schema versioning, migrations, SHA-256 integrity.
##
## Phase 1 / P1-004. Writes per-slot JSON files to `user://`, computes a
## stable SHA-256 checksum over everything except the checksum field itself,
## migrates older schemas forward on load, backs up the previous file before
## any migration.
##
## Schema + migration strategy: docs/decisions/ADR-0003-save-system.md.
##
## File layout (one per slot, slot 0 = "main" / Steam Cloud, 1-3 = local):
##   user://save_slot_<n>.json
##
## Migration backups (created on load when a migration runs):
##   user://save_slot_<n>.backup_v<old_schema_version>.json
##
## Steam Cloud sync is handled in Steam Partner-Backend (file pattern
## save_slot_0.json mapped to Cloud) + SteamAPI wrapper; SaveSystem itself
## is plain disk IO.
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal migration_applied(from_version: int, to_version: int)
signal save_corruption_detected(slot: int, reason: String)

# ----------------------------------------------------------------------------
# CONSTANTS
# ----------------------------------------------------------------------------
const CURRENT_SCHEMA_VERSION: int = 1
const SLOT_CLOUD: int = 0
const SLOT_LOCAL_1: int = 1
const SLOT_LOCAL_2: int = 2
const SLOT_LOCAL_3: int = 3
const MAX_SLOT: int = 3

const SAVE_PATH_TEMPLATE: String = "user://save_slot_%d.json"
const BACKUP_PATH_TEMPLATE: String = "user://save_slot_%d.backup_v%d.json"

## Map of schema migrations: from_version -> Callable(Dictionary) -> Dictionary.
## Add an entry when CURRENT_SCHEMA_VERSION is bumped:
##   const MIGRATIONS := { 1: _migrate_v1_to_v2 }
## Each migrator receives the parsed save dict at its old schema and must
## return a dict that matches the next schema. Wrap each new migrator with a
## test in tests/test_save_migration.gd.
const MIGRATIONS: Dictionary = {}

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Periodic auto-save Timer + Steam Cloud bootstrapping land in later
	# tickets (P1-013 polish / Phase 2 Steam integration). For now SaveSystem
	# is pure on-demand IO.
	pass

# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

## Persist current GameState to the given slot (0..MAX_SLOT). Returns true
## on full success. On any IO failure emits save_completed(slot, false).
func save(slot: int = SLOT_CLOUD) -> bool:
	if not _is_valid_slot(slot):
		push_error("[SaveSystem] save: invalid slot %d" % slot)
		save_completed.emit(slot, false)
		return false
	var path: String = SAVE_PATH_TEMPLATE % slot
	var ok: bool = save_to_path(path, slot)
	save_completed.emit(slot, ok)
	return ok

## Load the given slot back into GameState. Returns true on full success.
## Runs migrations if the file's schema_version is below CURRENT, backs up
## the original file first. Refuses to load if checksum is invalid or the
## file's schema_version is NEWER than CURRENT.
func load_slot(slot: int = SLOT_CLOUD) -> bool:
	if not _is_valid_slot(slot):
		push_error("[SaveSystem] load_slot: invalid slot %d" % slot)
		load_completed.emit(slot, false)
		return false
	var path: String = SAVE_PATH_TEMPLATE % slot
	var ok: bool = _load_state_from_path(path, slot)
	load_completed.emit(slot, ok)
	return ok

## Save current GameState to an arbitrary writable path. Used by tests and
## by export_to_file. Same on-disk format + checksum as save().
func save_to_path(path: String, slot_hint: int = -1) -> bool:
	var dict: Dictionary = _to_save_dict()
	dict["schema_version"] = CURRENT_SCHEMA_VERSION
	dict["saved_at_unix"] = int(Time.get_unix_time_from_system())
	dict["slot"] = slot_hint
	dict["game_version"] = String(ProjectSettings.get_setting(
		"application/config/version", "0.0.0-dev"))
	# Compute checksum AFTER all other fields are set; exclude the checksum
	# field itself from the digest (otherwise it's circular).
	dict.erase("checksum_sha256")
	var body_for_check: String = JSON.stringify(dict)
	dict["checksum_sha256"] = _sha256_hex(body_for_check)
	return _write_text(path, JSON.stringify(dict, "\t"))

## Run migrations forward from save_dict.schema_version to CURRENT.
## Returns the migrated dict. Caller is responsible for writing it back.
func migrate(save_dict: Dictionary) -> Dictionary:
	var version: int = int(save_dict.get("schema_version", 0))
	while version < CURRENT_SCHEMA_VERSION:
		if not MIGRATIONS.has(version):
			push_error("[SaveSystem] missing migration from v%d -> v%d" % [
				version, version + 1])
			return save_dict
		var migrator: Callable = MIGRATIONS[version]
		save_dict = migrator.call(save_dict)
		save_dict["schema_version"] = version + 1
		migration_applied.emit(version, version + 1)
		version += 1
	return save_dict

## Return list of save slot metadata for slot-picker UI.
func list_slots() -> Array:
	var out: Array = []
	for slot in range(MAX_SLOT + 1):
		var path: String = SAVE_PATH_TEMPLATE % slot
		out.append(_slot_info(slot, path))
	return out

## Copy a slot file to an external path (disaster recovery, manual backup).
## External path must be writable. Returns true on success.
func export_to_file(slot: int, external_path: String) -> bool:
	if not _is_valid_slot(slot):
		return false
	var src: String = SAVE_PATH_TEMPLATE % slot
	if not FileAccess.file_exists(src):
		push_error("[SaveSystem] export_to_file: slot %d has no file" % slot)
		return false
	var content: String = _read_text(src)
	if content.is_empty():
		return false
	return _write_text(external_path, content)

## Validate an external save file then copy it into the given slot.
## Returns true only after the checksum verifies — refuses to import
## corrupted files.
func import_from_file(external_path: String, target_slot: int) -> bool:
	if not _is_valid_slot(target_slot):
		return false
	if not FileAccess.file_exists(external_path):
		return false
	var content: String = _read_text(external_path)
	if content.is_empty():
		return false
	var parsed: Variant = _parse_and_verify(content, target_slot)
	if parsed == null:
		return false
	return _write_text(SAVE_PATH_TEMPLATE % target_slot, content)

## True if a save file exists in the given slot.
func slot_exists(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	return FileAccess.file_exists(SAVE_PATH_TEMPLATE % slot)

## Delete the save file for the given slot. Returns true if a file was removed.
## Backups are kept.
func delete_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	var path: String = SAVE_PATH_TEMPLATE % slot
	if not FileAccess.file_exists(path):
		return false
	var err: int = DirAccess.remove_absolute(path)
	return err == OK

# ----------------------------------------------------------------------------
# INTERNAL — load path
# ----------------------------------------------------------------------------

func _load_state_from_path(path: String, slot: int) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var content: String = _read_text(path)
	if content.is_empty():
		return false
	var parsed: Variant = _parse_and_verify(content, slot)
	if parsed == null:
		return false
	var dict: Dictionary = parsed as Dictionary
	# Schema-version check + migration.
	var save_version: int = int(dict.get("schema_version", 0))
	if save_version > CURRENT_SCHEMA_VERSION:
		push_error("[SaveSystem] slot %d schema_version %d > current %d, refusing to load" % [
			slot, save_version, CURRENT_SCHEMA_VERSION])
		save_corruption_detected.emit(slot, "future schema_version %d" % save_version)
		return false
	if save_version < CURRENT_SCHEMA_VERSION:
		# Backup current file before mutating.
		_backup_for_migration(slot, save_version)
		dict = migrate(dict)
	_apply_to_game_state(dict)
	return true

func _parse_and_verify(content: String, slot: int) -> Variant:
	var json: JSON = JSON.new()
	if json.parse(content) != OK:
		push_error("[SaveSystem] slot %d JSON parse error at line %d: %s" % [
			slot, json.get_error_line(), json.get_error_message()])
		save_corruption_detected.emit(slot, "JSON parse error")
		return null
	var data: Variant = json.data
	if not data is Dictionary:
		save_corruption_detected.emit(slot, "root is not a JSON object")
		return null
	var dict: Dictionary = data as Dictionary
	var stored: String = String(dict.get("checksum_sha256", ""))
	if stored.is_empty():
		save_corruption_detected.emit(slot, "missing checksum_sha256")
		return null
	# Recompute checksum without the checksum field.
	var dict_no_sum: Dictionary = dict.duplicate(true)
	dict_no_sum.erase("checksum_sha256")
	var expected: String = _sha256_hex(JSON.stringify(dict_no_sum))
	if expected != stored:
		save_corruption_detected.emit(slot, "checksum mismatch")
		return null
	return dict

func _backup_for_migration(slot: int, old_version: int) -> void:
	var src: String = SAVE_PATH_TEMPLATE % slot
	var dst: String = BACKUP_PATH_TEMPLATE % [slot, old_version]
	if not FileAccess.file_exists(src):
		return
	var content: String = _read_text(src)
	_write_text(dst, content)

# ----------------------------------------------------------------------------
# INTERNAL — IO helpers
# ----------------------------------------------------------------------------

func _read_text(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SaveSystem] read failed: %s (error %d)" % [
			path, FileAccess.get_open_error()])
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text

func _write_text(path: String, content: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] write failed: %s (error %d)" % [
			path, FileAccess.get_open_error()])
		return false
	file.store_string(content)
	file.close()
	return true

func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot <= MAX_SLOT

func _sha256_hex(s: String) -> String:
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(s.to_utf8_buffer())
	return ctx.finish().hex_encode()

func _slot_info(slot: int, path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return { "slot": slot, "exists": false }
	var content: String = _read_text(path)
	if content.is_empty():
		return { "slot": slot, "exists": true, "error": "empty" }
	var json: JSON = JSON.new()
	if json.parse(content) != OK:
		return { "slot": slot, "exists": true, "error": "parse error" }
	var d: Variant = json.data
	if not d is Dictionary:
		return { "slot": slot, "exists": true, "error": "not dict" }
	var game: Dictionary = (d as Dictionary).get("game", {}) as Dictionary
	return {
		"slot": slot,
		"exists": true,
		"schema_version": int((d as Dictionary).get("schema_version", 0)),
		"saved_at_unix": int((d as Dictionary).get("saved_at_unix", 0)),
		"stage": int(game.get("stage", 1)),
		"lifetime_dna": float(game.get("lifetime_dna", 0.0)),
	}

# ----------------------------------------------------------------------------
# INTERNAL — GameState <-> Dictionary mapping
# ----------------------------------------------------------------------------

func _to_save_dict() -> Dictionary:
	return {
		# Header — schema_version, saved_at_unix, slot, game_version, checksum
		# are filled in save_to_path() right before write.
		"game": {
			"dna": GameState.dna,
			"total_dna": GameState.total_dna,
			"lifetime_dna": GameState.lifetime_dna,
			"click_power": GameState.click_power,
			"dps": GameState.dps,
			"stage": GameState.stage,
			"divisions": GameState.divisions,
			"prestige_points": GameState.prestige_points,
			"prestige_multiplier": GameState.prestige_multiplier,
			"auto_clicker_level": GameState.auto_clicker_level,
			"start_time_unix": GameState.start_time_unix,
			"last_tick_unix": GameState.last_tick_unix,
			"last_real_tick_unix": GameState.last_real_tick_unix,
			"total_clicks": GameState.total_clicks,
			"total_crits": GameState.total_crits,
			"total_goldens": GameState.total_goldens,
			"active_mutation_id": GameState.active_mutation_id,
			"mutation_ends_at_unix": GameState.mutation_ends_at_unix,
		},
		"settings": {
			"sound": GameState.sound,
			"haptic": GameState.haptic,
			"buy_mode": GameState.buy_mode,
			"active_tab": GameState.active_tab,
		},
		"upgrades": GameState.upgrade_counts.duplicate(true),
		"research": GameState.research_unlocked.duplicate(true),
		"achievements": GameState.achievements_unlocked.duplicate(true),
		"abilities": GameState.abilities_state.duplicate(true),
	}

func _apply_to_game_state(dict: Dictionary) -> void:
	var game: Dictionary = dict.get("game", {}) as Dictionary
	GameState.dna = float(game.get("dna", 0.0))
	GameState.total_dna = float(game.get("total_dna", 0.0))
	GameState.lifetime_dna = float(game.get("lifetime_dna", 0.0))
	GameState.click_power = float(game.get("click_power", 1.0))
	GameState.dps = float(game.get("dps", 0.0))
	GameState.stage = int(game.get("stage", 1))
	GameState.divisions = int(game.get("divisions", 0))
	GameState.prestige_points = int(game.get("prestige_points", 0))
	GameState.prestige_multiplier = float(game.get("prestige_multiplier", 1.0))
	GameState.auto_clicker_level = int(game.get("auto_clicker_level", 0))
	GameState.start_time_unix = int(game.get("start_time_unix", 0))
	GameState.last_tick_unix = int(game.get("last_tick_unix", 0))
	GameState.last_real_tick_unix = int(game.get("last_real_tick_unix", 0))
	GameState.total_clicks = int(game.get("total_clicks", 0))
	GameState.total_crits = int(game.get("total_crits", 0))
	GameState.total_goldens = int(game.get("total_goldens", 0))
	GameState.active_mutation_id = String(game.get("active_mutation_id", ""))
	GameState.mutation_ends_at_unix = int(game.get("mutation_ends_at_unix", 0))

	var settings: Dictionary = dict.get("settings", {}) as Dictionary
	GameState.sound = bool(settings.get("sound", true))
	GameState.haptic = bool(settings.get("haptic", true))
	# buy_mode is Variant (int or "max")
	GameState.buy_mode = settings.get("buy_mode", 1)
	GameState.active_tab = String(settings.get("active_tab", "auto"))

	# Nested dicts: replace wholesale (no merging — load == rehydrate).
	GameState.upgrade_counts = (dict.get("upgrades", {}) as Dictionary).duplicate(true)
	GameState.research_unlocked = (dict.get("research", {}) as Dictionary).duplicate(true)
	GameState.achievements_unlocked = (dict.get("achievements", {}) as Dictionary).duplicate(true)
	GameState.abilities_state = (dict.get("abilities", {}) as Dictionary).duplicate(true)
