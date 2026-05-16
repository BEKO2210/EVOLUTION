extends SceneTree
##
## Headless test for SaveSystem (Phase 1 / P1-004).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_save_system.gd
##
## Uses SLOT_LOCAL_3 (slot 3). WARNING: if you have a real save in slot 3
## from playing the game, this test overwrites it. Tests delete the file
## on teardown. Tests do not touch slots 0/1/2 — your main saves stay safe.
##
## Coverage:
##   - round-trip preserves all GameState fields
##   - 100-cycle save/load loop with no degradation
##   - checksum corruption is detected on load
##   - JSON corruption is detected on load
##   - missing-checksum is detected
##   - tampered field is detected via checksum mismatch
##   - non-existent slot loads return false cleanly
##   - export_to_file + import_from_file round-trip
##   - import refuses a corrupted external file
##   - list_slots returns metadata for existing slots
##

const TEST_SLOT: int = SaveSystem.SLOT_LOCAL_3
const TEST_EXPORT_PATH: String = "user://_test_export.json"

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	_setup()
	_run_all()
	_teardown()
	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Setup / teardown
# ----------------------------------------------------------------------------

func _setup() -> void:
	# Cleanup any leftover files from prior aborted runs.
	_cleanup_test_files()

func _teardown() -> void:
	_cleanup_test_files()

func _cleanup_test_files() -> void:
	var paths: PackedStringArray = PackedStringArray([
		"user://save_slot_%d.json" % TEST_SLOT,
		"user://save_slot_%d.backup_v0.json" % TEST_SLOT,
		"user://save_slot_%d.backup_v1.json" % TEST_SLOT,
		TEST_EXPORT_PATH,
	])
	for p in paths:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _run_all() -> void:
	_test_round_trip_preserves_fields()
	_test_100_cycle_no_degradation()
	_test_checksum_corruption_detected()
	_test_json_corruption_detected()
	_test_missing_checksum_detected()
	_test_tampered_field_detected()
	_test_missing_slot_returns_false()
	_test_invalid_slot_rejected()
	_test_export_import_round_trip()
	_test_import_refuses_corrupted()
	_test_list_slots_reports_metadata()
	_test_slot_exists_helper()
	_test_delete_slot()

func _test_round_trip_preserves_fields() -> void:
	_populate_known_state()
	var saved_state: Dictionary = _snapshot_state()
	var save_ok: bool = SaveSystem.save(TEST_SLOT)
	_assert(save_ok, "save() returned false")
	_reset_state()
	_assert(GameState.dna == 0.0, "reset failed (sanity)")
	var load_ok: bool = SaveSystem.load_slot(TEST_SLOT)
	_assert(load_ok, "load_slot() returned false")
	_assert_state_matches(saved_state, "round-trip")

func _test_100_cycle_no_degradation() -> void:
	_populate_known_state()
	var snapshot: Dictionary = _snapshot_state()
	for i in 100:
		var ok_save: bool = SaveSystem.save(TEST_SLOT)
		if not ok_save:
			_failures.append("100-cycle: save %d failed" % i)
			return
		_reset_state()
		var ok_load: bool = SaveSystem.load_slot(TEST_SLOT)
		if not ok_load:
			_failures.append("100-cycle: load %d failed" % i)
			return
	_assert_state_matches(snapshot, "100-cycle final")

func _test_checksum_corruption_detected() -> void:
	_populate_known_state()
	SaveSystem.save(TEST_SLOT)
	# Rewrite checksum to a known-bad value, leave everything else intact.
	var path: String = "user://save_slot_%d.json" % TEST_SLOT
	var json: JSON = JSON.new()
	json.parse(_read(path))
	var d: Dictionary = json.data
	d["checksum_sha256"] = "0000000000000000000000000000000000000000000000000000000000000000"
	_write(path, JSON.stringify(d, "\t"))
	var load_ok: bool = SaveSystem.load_slot(TEST_SLOT)
	_assert(not load_ok, "load_slot should reject bad checksum")

func _test_json_corruption_detected() -> void:
	_populate_known_state()
	SaveSystem.save(TEST_SLOT)
	var path: String = "user://save_slot_%d.json" % TEST_SLOT
	_write(path, "{ not valid json at all")
	var load_ok: bool = SaveSystem.load_slot(TEST_SLOT)
	_assert(not load_ok, "load_slot should reject malformed JSON")

func _test_missing_checksum_detected() -> void:
	_populate_known_state()
	SaveSystem.save(TEST_SLOT)
	var path: String = "user://save_slot_%d.json" % TEST_SLOT
	var json: JSON = JSON.new()
	json.parse(_read(path))
	var d: Dictionary = json.data
	d.erase("checksum_sha256")
	_write(path, JSON.stringify(d, "\t"))
	var load_ok: bool = SaveSystem.load_slot(TEST_SLOT)
	_assert(not load_ok, "load_slot should reject missing checksum")

func _test_tampered_field_detected() -> void:
	# Modify a game field WITHOUT updating the checksum — must be detected.
	_populate_known_state()
	SaveSystem.save(TEST_SLOT)
	var path: String = "user://save_slot_%d.json" % TEST_SLOT
	var json: JSON = JSON.new()
	json.parse(_read(path))
	var d: Dictionary = json.data
	# Bump DNA by 1 million but DON'T recompute checksum.
	(d["game"] as Dictionary)["dna"] = 999999999.0
	_write(path, JSON.stringify(d, "\t"))
	var load_ok: bool = SaveSystem.load_slot(TEST_SLOT)
	_assert(not load_ok, "load_slot should reject tampered field via checksum")

func _test_missing_slot_returns_false() -> void:
	_cleanup_test_files()
	var load_ok: bool = SaveSystem.load_slot(TEST_SLOT)
	_assert(not load_ok, "load_slot on missing file should return false")

func _test_invalid_slot_rejected() -> void:
	var save_ok: bool = SaveSystem.save(99)
	_assert(not save_ok, "save(99) should be rejected")
	var load_ok: bool = SaveSystem.load_slot(99)
	_assert(not load_ok, "load_slot(99) should be rejected")
	var save_neg: bool = SaveSystem.save(-1)
	_assert(not save_neg, "save(-1) should be rejected")

func _test_export_import_round_trip() -> void:
	_populate_known_state()
	var snapshot: Dictionary = _snapshot_state()
	SaveSystem.save(TEST_SLOT)
	var export_ok: bool = SaveSystem.export_to_file(TEST_SLOT, TEST_EXPORT_PATH)
	_assert(export_ok, "export_to_file failed")
	_assert(FileAccess.file_exists(TEST_EXPORT_PATH), "exported file not on disk")
	# Erase the slot, import back from external file.
	SaveSystem.delete_slot(TEST_SLOT)
	_reset_state()
	var import_ok: bool = SaveSystem.import_from_file(TEST_EXPORT_PATH, TEST_SLOT)
	_assert(import_ok, "import_from_file failed")
	var load_ok: bool = SaveSystem.load_slot(TEST_SLOT)
	_assert(load_ok, "load_slot after import failed")
	_assert_state_matches(snapshot, "export-import round-trip")

func _test_import_refuses_corrupted() -> void:
	_write(TEST_EXPORT_PATH, "{ broken file }")
	var import_ok: bool = SaveSystem.import_from_file(TEST_EXPORT_PATH, TEST_SLOT)
	_assert(not import_ok, "import_from_file should reject malformed JSON")
	# Clean external file.
	if FileAccess.file_exists(TEST_EXPORT_PATH):
		DirAccess.remove_absolute(TEST_EXPORT_PATH)

func _test_list_slots_reports_metadata() -> void:
	_populate_known_state()
	SaveSystem.save(TEST_SLOT)
	var slots: Array = SaveSystem.list_slots()
	_assert(slots.size() == SaveSystem.MAX_SLOT + 1,
		"list_slots should return MAX_SLOT+1 entries, got %d" % slots.size())
	var meta: Dictionary = slots[TEST_SLOT] as Dictionary
	_assert(meta.get("exists", false), "test slot should report exists=true")
	_assert(int(meta.get("schema_version", 0)) == SaveSystem.CURRENT_SCHEMA_VERSION,
		"list_slots schema_version mismatch")
	_assert(int(meta.get("stage", 0)) == GameState.stage,
		"list_slots stage mismatch")

func _test_slot_exists_helper() -> void:
	_cleanup_test_files()
	_assert(not SaveSystem.slot_exists(TEST_SLOT), "slot_exists should be false after cleanup")
	_populate_known_state()
	SaveSystem.save(TEST_SLOT)
	_assert(SaveSystem.slot_exists(TEST_SLOT), "slot_exists should be true after save")

func _test_delete_slot() -> void:
	_populate_known_state()
	SaveSystem.save(TEST_SLOT)
	_assert(SaveSystem.slot_exists(TEST_SLOT), "pre-condition: slot should exist")
	var deleted: bool = SaveSystem.delete_slot(TEST_SLOT)
	_assert(deleted, "delete_slot returned false")
	_assert(not SaveSystem.slot_exists(TEST_SLOT), "slot should not exist after delete")

# ----------------------------------------------------------------------------
# GameState helpers
# ----------------------------------------------------------------------------

func _populate_known_state() -> void:
	GameState.dna = 1234.5
	GameState.total_dna = 9876.5
	GameState.lifetime_dna = 12345.67
	GameState.click_power = 42.0
	GameState.dps = 17.5
	GameState.stage = 7
	GameState.divisions = 2
	GameState.prestige_points = 4
	GameState.prestige_multiplier = 1.4641  # pow(1.10, 4)
	GameState.auto_clicker_level = 1
	GameState.start_time_unix = 1736000000
	GameState.last_tick_unix = 1736889600
	GameState.last_real_tick_unix = 1736889600
	GameState.total_clicks = 15234
	GameState.total_crits = 412
	GameState.total_goldens = 7
	GameState.sound = true
	GameState.haptic = false
	GameState.buy_mode = 10
	GameState.active_tab = "click"
	GameState.upgrade_counts = {
		"auto_001": 12,
		"auto_002": 5,
		"click_001": 8,
	}
	GameState.research_unlocked = { "research_001": 1736000000 }
	GameState.achievements_unlocked = { "achievement_001": 1736000000 }
	GameState.abilities_state = {
		"ability_001": { "last_used_unix": 1736000000, "active_until_unix": 0 }
	}
	GameState.active_mutation_id = "frenzy"
	GameState.mutation_ends_at_unix = 1736890000

func _reset_state() -> void:
	GameState.dna = 0.0
	GameState.total_dna = 0.0
	GameState.lifetime_dna = 0.0
	GameState.click_power = 1.0
	GameState.dps = 0.0
	GameState.stage = 1
	GameState.divisions = 0
	GameState.prestige_points = 0
	GameState.prestige_multiplier = 1.0
	GameState.auto_clicker_level = 0
	GameState.start_time_unix = 0
	GameState.last_tick_unix = 0
	GameState.last_real_tick_unix = 0
	GameState.total_clicks = 0
	GameState.total_crits = 0
	GameState.total_goldens = 0
	GameState.sound = true
	GameState.haptic = true
	GameState.buy_mode = 1
	GameState.active_tab = "auto"
	GameState.upgrade_counts = {}
	GameState.research_unlocked = {}
	GameState.achievements_unlocked = {}
	GameState.abilities_state = {}
	GameState.active_mutation_id = ""
	GameState.mutation_ends_at_unix = 0

func _snapshot_state() -> Dictionary:
	return {
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
		"sound": GameState.sound,
		"haptic": GameState.haptic,
		"buy_mode": GameState.buy_mode,
		"active_tab": GameState.active_tab,
		"upgrade_counts": GameState.upgrade_counts.duplicate(true),
		"research_unlocked": GameState.research_unlocked.duplicate(true),
		"achievements_unlocked": GameState.achievements_unlocked.duplicate(true),
		"abilities_state": GameState.abilities_state.duplicate(true),
		"active_mutation_id": GameState.active_mutation_id,
		"mutation_ends_at_unix": GameState.mutation_ends_at_unix,
	}

func _assert_state_matches(snap: Dictionary, label: String) -> void:
	for key in snap.keys():
		var actual: Variant = GameState.get(key)
		var expected: Variant = snap[key]
		if not _values_equal(actual, expected):
			_failures.append("%s: field '%s' mismatch — got %s, expected %s" % [
				label, key, str(actual), str(expected)])
			return
	_passes += 1

func _values_equal(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var da: Dictionary = a as Dictionary
		var db: Dictionary = b as Dictionary
		if da.size() != db.size():
			return false
		for k in da.keys():
			if not db.has(k):
				return false
			if not _values_equal(da[k], db[k]):
				return false
		return true
	return a == b

# ----------------------------------------------------------------------------
# Generic helpers
# ----------------------------------------------------------------------------

func _read(path: String) -> String:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var t: String = f.get_as_text()
	f.close()
	return t

func _write(path: String, content: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(content)
	f.close()

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
	else:
		_failures.append(msg)

func _report() -> void:
	print("")
	print("================================================================")
	print("SaveSystem tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
