extends Node
##
## DataLoader — loads all data/*.json into typed in-memory tables.
##
## Phase 1 / P1-003. Reads:
##   data/balance_constants.json
##   data/stages.json
##   data/upgrades_auto.json
##   data/upgrades_click.json
##   data/research.json
##   data/abilities.json
##   data/achievements.json
##
## Validates per-file schemas (required fields, types, enums), checks
## cross-table references (unlock chains), and exposes O(1) lookups by ID
## plus ordered arrays for UI.
##
## Strategy: docs/decisions/ADR-0004-data-driven-upgrades.md
## Schema spec: data/schema-notes.md
##
## On schema violation: emits data_validation_failed and returns false.
## Game code should NOT proceed with is_loaded == false.
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal data_loaded()
signal data_validation_failed(file: String, reason: String)

# ----------------------------------------------------------------------------
# PATHS
# ----------------------------------------------------------------------------
const PATH_BALANCE: String = "res://data/balance_constants.json"
const PATH_STAGES: String = "res://data/stages.json"
const PATH_UPGRADES_AUTO: String = "res://data/upgrades_auto.json"
const PATH_UPGRADES_CLICK: String = "res://data/upgrades_click.json"
const PATH_RESEARCH: String = "res://data/research.json"
const PATH_ABILITIES: String = "res://data/abilities.json"
const PATH_ACHIEVEMENTS: String = "res://data/achievements.json"

# ----------------------------------------------------------------------------
# ENUM ALLOWLISTS
# ----------------------------------------------------------------------------
const RESEARCH_EFFECT_KINDS: PackedStringArray = PackedStringArray([
	"dps_multiplier",
	"click_multiplier",
	"crit_chance_add",
	"crit_multiplier_set",
	"golden_spawn_rate",
	"golden_reward_mult",
	"click_dps_share",
	"combo_max_multiplier",
	"combo_time_multiplier",
	"mutation_rate",
	"stage_bonus_amplify",
	"offline_full",
])

const ABILITY_KINDS: PackedStringArray = PackedStringArray([
	"dps_multiplier",
	"click_multiplier",
	"instant_dps_seconds",
	"autoclick_burst",
])

const ACHIEVEMENT_CONDITION_KINDS: PackedStringArray = PackedStringArray([
	"total_clicks_at_least",
	"lifetime_dna_at_least",
	"stage_at_least",
	"total_crits_at_least",
	"total_goldens_at_least",
	"divisions_at_least",
	"prestige_points_at_least",
	"all_auto_upgrades_owned",
	"all_click_upgrades_owned",
])

const ACHIEVEMENT_REWARD_KEYS: PackedStringArray = PackedStringArray([
	"click_multiplier",
	"dps_multiplier",
	"all_multiplier",
	"crit_chance_add",
	"golden_spawn_rate",
	"golden_reward_multiplier",
])

# ----------------------------------------------------------------------------
# DATA TABLES (populated by load_all)
# ----------------------------------------------------------------------------
var stages: Array = []
var upgrades_auto: Array = []
var upgrades_click: Array = []
var research: Array = []
var abilities: Array = []
var achievements: Array = []
var balance: Dictionary = {}

# ID -> Dictionary lookups for fast access.
var _stage_by_id: Dictionary = {}
var _upgrade_auto_by_id: Dictionary = {}
var _upgrade_click_by_id: Dictionary = {}
var _research_by_id: Dictionary = {}
var _ability_by_id: Dictionary = {}
var _achievement_by_id: Dictionary = {}

var is_loaded: bool = false
var _last_errors: PackedStringArray = PackedStringArray()

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Auto-load on boot. Game code that needs DataLoader must check is_loaded
	# (or await data_loaded) before reading.
	load_all()

# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

## Load every data/*.json file, validate schemas, populate lookups.
## Returns true on full success.
func load_all() -> bool:
	_reset()
	var ok: bool = true
	ok = _load_balance(PATH_BALANCE) and ok
	ok = _load_stages(PATH_STAGES) and ok
	ok = _load_upgrades_auto(PATH_UPGRADES_AUTO) and ok
	ok = _load_upgrades_click(PATH_UPGRADES_CLICK) and ok
	ok = _load_research(PATH_RESEARCH) and ok
	ok = _load_abilities(PATH_ABILITIES) and ok
	ok = _load_achievements(PATH_ACHIEVEMENTS) and ok
	if ok:
		ok = _validate_cross_table()
	is_loaded = ok
	if ok:
		data_loaded.emit()
	return ok

func get_stage(stage_id: String) -> Variant:
	return _stage_by_id.get(stage_id, null)

func get_stage_by_tier(tier: int) -> Variant:
	if tier < 1 or tier > stages.size():
		return null
	return stages[tier - 1]

func get_upgrade_auto(upgrade_id: String) -> Variant:
	return _upgrade_auto_by_id.get(upgrade_id, null)

func get_upgrade_click(upgrade_id: String) -> Variant:
	return _upgrade_click_by_id.get(upgrade_id, null)

func get_research(research_id: String) -> Variant:
	return _research_by_id.get(research_id, null)

func get_ability(ability_id: String) -> Variant:
	return _ability_by_id.get(ability_id, null)

func get_achievement(achievement_id: String) -> Variant:
	return _achievement_by_id.get(achievement_id, null)

## Read-only view of last load errors (empty if last load_all was clean).
func get_last_errors() -> PackedStringArray:
	return _last_errors

# ----------------------------------------------------------------------------
# INTERNAL — load + validate
# ----------------------------------------------------------------------------

func _reset() -> void:
	stages.clear()
	upgrades_auto.clear()
	upgrades_click.clear()
	research.clear()
	abilities.clear()
	achievements.clear()
	balance.clear()
	_stage_by_id.clear()
	_upgrade_auto_by_id.clear()
	_upgrade_click_by_id.clear()
	_research_by_id.clear()
	_ability_by_id.clear()
	_achievement_by_id.clear()
	_last_errors = PackedStringArray()
	is_loaded = false

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_fail(path, "file not found")
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail(path, "cannot open: error %d" % FileAccess.get_open_error())
		return null
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		_fail(path, "JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return null
	return json.data

func _require_dict(path: String, value: Variant) -> bool:
	if not value is Dictionary:
		_fail(path, "root must be a JSON object")
		return false
	return true

func _require_items_array(path: String, root: Dictionary) -> Variant:
	if not root.has("items"):
		_fail(path, "missing 'items' array")
		return null
	if not root["items"] is Array:
		_fail(path, "'items' must be an array")
		return null
	return root["items"]

func _require_field(path: String, item: Dictionary, field: String, want_types: Array, context: String) -> bool:
	if not item.has(field):
		_fail(path, "%s: missing required field '%s'" % [context, field])
		return false
	var value: Variant = item[field]
	for t in want_types:
		if typeof(value) == t:
			return true
	_fail(path, "%s: field '%s' has wrong type (got %s)" % [context, field, type_string(typeof(value))])
	return false

# ---------- per-file loaders ----------

func _load_balance(path: String) -> bool:
	var root: Variant = _read_json(path)
	if root == null or not _require_dict(path, root):
		return false
	for required in ["economy", "prestige", "division", "crit", "combo", "offline_progression", "tick_rates"]:
		if not root.has(required):
			_fail(path, "missing top-level section '%s'" % required)
			return false
	balance = root
	return true

func _load_stages(path: String) -> bool:
	var root: Variant = _read_json(path)
	if root == null or not _require_dict(path, root):
		return false
	var items: Variant = _require_items_array(path, root)
	if items == null:
		return false
	for i in items.size():
		var item = items[i]
		if not item is Dictionary:
			_fail(path, "items[%d] is not a dict" % i)
			return false
		var ctx: String = "items[%d]" % i
		if not _require_field(path, item, "id", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "tier", [TYPE_INT, TYPE_FLOAT], ctx): return false
		if not _require_field(path, item, "name_key", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "threshold_dna", [TYPE_INT, TYPE_FLOAT], ctx): return false
		if not _require_field(path, item, "bonus_multiplier", [TYPE_INT, TYPE_FLOAT], ctx): return false
		var id: String = item["id"]
		if _stage_by_id.has(id):
			_fail(path, "%s: duplicate id '%s'" % [ctx, id])
			return false
		stages.append(item)
		_stage_by_id[id] = item
	# Monotonic-threshold check.
	for i in range(1, stages.size()):
		var prev_t: float = float(stages[i - 1]["threshold_dna"])
		var cur_t: float = float(stages[i]["threshold_dna"])
		if cur_t < prev_t:
			_fail(path, "thresholds non-monotonic: tier %d (%g) < tier %d (%g)" % [
				i + 1, cur_t, i, prev_t])
			return false
	# First stage must start at 0.
	if stages.size() > 0 and float(stages[0]["threshold_dna"]) != 0.0:
		_fail(path, "first stage threshold_dna must be 0 (game starts there)")
		return false
	return true

func _load_upgrades_generic(path: String, target_array: Array, target_lookup: Dictionary, power_field: String) -> bool:
	var root: Variant = _read_json(path)
	if root == null or not _require_dict(path, root):
		return false
	var items: Variant = _require_items_array(path, root)
	if items == null:
		return false
	for i in items.size():
		var item = items[i]
		if not item is Dictionary:
			_fail(path, "items[%d] is not a dict" % i)
			return false
		var ctx: String = "items[%d]" % i
		if not _require_field(path, item, "id", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "tier", [TYPE_INT, TYPE_FLOAT], ctx): return false
		if not _require_field(path, item, "name_key", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "desc_key", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "cost_base", [TYPE_INT, TYPE_FLOAT], ctx): return false
		if not _require_field(path, item, power_field, [TYPE_INT, TYPE_FLOAT], ctx): return false
		# unlock_after_id is required but may be null
		if not item.has("unlock_after_id"):
			_fail(path, "%s: missing required field 'unlock_after_id' (may be null)" % ctx)
			return false
		var unlock: Variant = item["unlock_after_id"]
		if unlock != null and not (unlock is String):
			_fail(path, "%s: unlock_after_id must be string or null" % ctx)
			return false
		var id: String = item["id"]
		if target_lookup.has(id):
			_fail(path, "%s: duplicate id '%s'" % [ctx, id])
			return false
		target_array.append(item)
		target_lookup[id] = item
	return true

func _load_upgrades_auto(path: String) -> bool:
	return _load_upgrades_generic(path, upgrades_auto, _upgrade_auto_by_id, "dps_base")

func _load_upgrades_click(path: String) -> bool:
	return _load_upgrades_generic(path, upgrades_click, _upgrade_click_by_id, "click_power_base")

func _load_research(path: String) -> bool:
	var root: Variant = _read_json(path)
	if root == null or not _require_dict(path, root):
		return false
	var items: Variant = _require_items_array(path, root)
	if items == null:
		return false
	for i in items.size():
		var item = items[i]
		if not item is Dictionary:
			_fail(path, "items[%d] is not a dict" % i)
			return false
		var ctx: String = "items[%d]" % i
		if not _require_field(path, item, "id", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "name_key", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "desc_key", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "cost_dna", [TYPE_INT, TYPE_FLOAT], ctx): return false
		if not _require_field(path, item, "effect", [TYPE_DICTIONARY], ctx): return false
		var effect: Dictionary = item["effect"]
		if not effect.has("kind"):
			_fail(path, "%s: effect.kind missing" % ctx)
			return false
		var kind: String = String(effect["kind"])
		if not (kind in RESEARCH_EFFECT_KINDS):
			_fail(path, "%s: effect.kind '%s' not in allowlist" % [ctx, kind])
			return false
		var id: String = item["id"]
		if _research_by_id.has(id):
			_fail(path, "%s: duplicate id '%s'" % [ctx, id])
			return false
		research.append(item)
		_research_by_id[id] = item
	return true

func _load_abilities(path: String) -> bool:
	var root: Variant = _read_json(path)
	if root == null or not _require_dict(path, root):
		return false
	var items: Variant = _require_items_array(path, root)
	if items == null:
		return false
	for i in items.size():
		var item = items[i]
		if not item is Dictionary:
			_fail(path, "items[%d] is not a dict" % i)
			return false
		var ctx: String = "items[%d]" % i
		if not _require_field(path, item, "id", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "name_key", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "desc_key", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "kind", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "duration_ms", [TYPE_INT, TYPE_FLOAT], ctx): return false
		if not _require_field(path, item, "cooldown_ms", [TYPE_INT, TYPE_FLOAT], ctx): return false
		var kind: String = String(item["kind"])
		if not (kind in ABILITY_KINDS):
			_fail(path, "%s: kind '%s' not in allowlist" % [ctx, kind])
			return false
		# kind-specific required fields
		match kind:
			"dps_multiplier", "click_multiplier":
				if not _require_field(path, item, "multiplier", [TYPE_INT, TYPE_FLOAT], ctx): return false
			"instant_dps_seconds":
				if not _require_field(path, item, "instant_dps_seconds", [TYPE_INT, TYPE_FLOAT], ctx): return false
			"autoclick_burst":
				if not _require_field(path, item, "autoclick_count", [TYPE_INT, TYPE_FLOAT], ctx): return false
		var id: String = item["id"]
		if _ability_by_id.has(id):
			_fail(path, "%s: duplicate id '%s'" % [ctx, id])
			return false
		abilities.append(item)
		_ability_by_id[id] = item
	return true

func _load_achievements(path: String) -> bool:
	var root: Variant = _read_json(path)
	if root == null or not _require_dict(path, root):
		return false
	var items: Variant = _require_items_array(path, root)
	if items == null:
		return false
	for i in items.size():
		var item = items[i]
		if not item is Dictionary:
			_fail(path, "items[%d] is not a dict" % i)
			return false
		var ctx: String = "items[%d]" % i
		if not _require_field(path, item, "id", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "name_key", [TYPE_STRING], ctx): return false
		if not _require_field(path, item, "condition", [TYPE_DICTIONARY], ctx): return false
		if not _require_field(path, item, "reward", [TYPE_DICTIONARY], ctx): return false
		var cond: Dictionary = item["condition"]
		if not cond.has("kind") or not cond.has("threshold"):
			_fail(path, "%s: condition needs kind+threshold" % ctx)
			return false
		var cond_kind: String = String(cond["kind"])
		if not (cond_kind in ACHIEVEMENT_CONDITION_KINDS):
			_fail(path, "%s: condition.kind '%s' not in allowlist" % [ctx, cond_kind])
			return false
		# reward.* keys must all be known
		var reward: Dictionary = item["reward"]
		for key in reward.keys():
			if not (String(key) in ACHIEVEMENT_REWARD_KEYS):
				_fail(path, "%s: reward.%s not in allowlist" % [ctx, key])
				return false
		var id: String = item["id"]
		if _achievement_by_id.has(id):
			_fail(path, "%s: duplicate id '%s'" % [ctx, id])
			return false
		achievements.append(item)
		_achievement_by_id[id] = item
	return true

func _validate_cross_table() -> bool:
	# upgrade.unlock_after_id (if non-null) must reference an existing upgrade
	# in the same table.
	for u in upgrades_auto:
		var after: Variant = u["unlock_after_id"]
		if after != null and not _upgrade_auto_by_id.has(after):
			_fail(PATH_UPGRADES_AUTO, "upgrade '%s': unlock_after_id '%s' does not exist" % [u["id"], after])
			return false
	for u in upgrades_click:
		var after: Variant = u["unlock_after_id"]
		if after != null and not _upgrade_click_by_id.has(after):
			_fail(PATH_UPGRADES_CLICK, "upgrade '%s': unlock_after_id '%s' does not exist" % [u["id"], after])
			return false
	return true

func _fail(file: String, reason: String) -> void:
	var msg: String = "[DataLoader] %s — %s" % [file, reason]
	push_error(msg)
	_last_errors.append(msg)
	data_validation_failed.emit(file, reason)
