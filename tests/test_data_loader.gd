extends SceneTree
##
## Headless test for DataLoader (Phase 1 / P1-003).
##
## Run from the repo root with:
##   godot --headless --path . --script tests/test_data_loader.gd
##
## Exits with status 0 on success, 1 on any assertion failure. CI in later
## phases will hook this into the build pipeline.
##
## A proper GUT-based test suite lands in a later phase; this is a minimal
## standalone runner that proves the data layer is self-consistent without
## introducing a new third-party dependency in P1-003.
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	# Autoloads are available because Godot configures them before _initialize
	# when launched via --script (they're part of the project config).
	_run_all()
	_report()
	quit(0 if _failures.is_empty() else 1)

func _run_all() -> void:
	_test_loads_all_files()
	_test_expected_item_counts()
	_test_no_duplicate_ids()
	_test_stage_thresholds_monotonic()
	_test_stage_1_starts_at_zero()
	_test_balance_has_expected_constants()
	_test_research_effect_kinds_allowlisted()
	_test_ability_kinds_allowlisted()
	_test_achievement_condition_kinds_allowlisted()
	_test_achievement_reward_keys_allowlisted()
	_test_unlock_chain_auto()
	_test_unlock_chain_click()
	_test_lookups_return_real_data()
	_test_lookups_safe_on_miss()
	_test_stage_by_tier_helper()
	_test_stage_visuals_present_for_every_stage()
	_test_stage_visuals_signature_allowlisted()
	_test_stage_visuals_shape_kind_allowlisted()
	_test_stage_visuals_colors_are_hex()
	_test_stage_visual_lookups()

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_loads_all_files() -> void:
	var ok: bool = DataLoader.load_all()
	_assert(ok, "DataLoader.load_all() returned false. Errors: %s" % str(DataLoader.get_last_errors()))
	_assert(DataLoader.is_loaded, "DataLoader.is_loaded is false after load_all()")

func _test_expected_item_counts() -> void:
	_assert_eq(DataLoader.stages.size(), 30, "stages count")
	_assert_eq(DataLoader.stage_visuals.size(), 30, "stage_visuals count")
	_assert_eq(DataLoader.upgrades_auto.size(), 30, "upgrades_auto count")
	_assert_eq(DataLoader.upgrades_click.size(), 30, "upgrades_click count")
	_assert_eq(DataLoader.research.size(), 12, "research count")
	_assert_eq(DataLoader.abilities.size(), 4, "abilities count")
	_assert_eq(DataLoader.achievements.size(), 27, "achievements count")

func _test_no_duplicate_ids() -> void:
	_assert_no_duplicates(DataLoader.stages, "stages")
	_assert_no_duplicates(DataLoader.upgrades_auto, "upgrades_auto")
	_assert_no_duplicates(DataLoader.upgrades_click, "upgrades_click")
	_assert_no_duplicates(DataLoader.research, "research")
	_assert_no_duplicates(DataLoader.abilities, "abilities")
	_assert_no_duplicates(DataLoader.achievements, "achievements")

func _test_stage_thresholds_monotonic() -> void:
	for i in range(1, DataLoader.stages.size()):
		var prev_t: float = float(DataLoader.stages[i - 1]["threshold_dna"])
		var cur_t: float = float(DataLoader.stages[i]["threshold_dna"])
		_assert(cur_t > prev_t, "stage %d threshold (%g) must be > stage %d (%g)" % [
			i + 1, cur_t, i, prev_t])

func _test_stage_1_starts_at_zero() -> void:
	_assert_eq(float(DataLoader.stages[0]["threshold_dna"]), 0.0, "stage 1 threshold")

func _test_balance_has_expected_constants() -> void:
	_assert(DataLoader.balance.has("economy"), "balance.economy missing")
	var economy: Dictionary = DataLoader.balance["economy"]
	_assert_eq(float(economy.get("cost_growth", 0.0)), 1.15, "cost_growth")
	var milestones: Array = economy.get("milestone_thresholds", [])
	_assert_eq(milestones.size(), 4, "milestone count")
	_assert(DataLoader.balance.has("prestige"), "balance.prestige missing")
	_assert_eq(
		float(DataLoader.balance["prestige"].get("lifetime_dna_threshold", 0)),
		1000000.0,
		"prestige threshold")

func _test_research_effect_kinds_allowlisted() -> void:
	for r in DataLoader.research:
		var kind: String = String(r["effect"]["kind"])
		_assert(
			kind in DataLoader.RESEARCH_EFFECT_KINDS,
			"research '%s' has unknown effect.kind '%s'" % [r["id"], kind])

func _test_ability_kinds_allowlisted() -> void:
	for a in DataLoader.abilities:
		var kind: String = String(a["kind"])
		_assert(
			kind in DataLoader.ABILITY_KINDS,
			"ability '%s' has unknown kind '%s'" % [a["id"], kind])

func _test_achievement_condition_kinds_allowlisted() -> void:
	for a in DataLoader.achievements:
		var kind: String = String(a["condition"]["kind"])
		_assert(
			kind in DataLoader.ACHIEVEMENT_CONDITION_KINDS,
			"achievement '%s' has unknown condition.kind '%s'" % [a["id"], kind])

func _test_achievement_reward_keys_allowlisted() -> void:
	for a in DataLoader.achievements:
		var reward: Dictionary = a["reward"]
		for key in reward.keys():
			_assert(
				String(key) in DataLoader.ACHIEVEMENT_REWARD_KEYS,
				"achievement '%s' has unknown reward key '%s'" % [a["id"], key])

func _test_unlock_chain_auto() -> void:
	for u in DataLoader.upgrades_auto:
		var after: Variant = u["unlock_after_id"]
		if after != null:
			_assert(
				DataLoader.get_upgrade_auto(after) != null,
				"upgrade '%s' unlocks after '%s' which does not exist" % [u["id"], after])

func _test_unlock_chain_click() -> void:
	for u in DataLoader.upgrades_click:
		var after: Variant = u["unlock_after_id"]
		if after != null:
			_assert(
				DataLoader.get_upgrade_click(after) != null,
				"upgrade '%s' unlocks after '%s' which does not exist" % [u["id"], after])

func _test_lookups_return_real_data() -> void:
	# Spot-check that ID lookups return the right dicts.
	var stage_1: Variant = DataLoader.get_stage("stage_001")
	_assert(stage_1 != null, "get_stage('stage_001') returned null")
	_assert(int(stage_1["tier"]) == 1, "stage_001.tier should be 1")
	var mito: Variant = DataLoader.get_upgrade_auto("auto_001")
	_assert(mito != null, "get_upgrade_auto('auto_001') returned null")
	_assert(float(mito["cost_base"]) == 60.0, "auto_001.cost_base should be 60")
	var enzyme: Variant = DataLoader.get_upgrade_click("click_001")
	_assert(enzyme != null, "get_upgrade_click('click_001') returned null")
	_assert(float(enzyme["cost_base"]) == 200.0, "click_001.cost_base should be 200")
	var photo: Variant = DataLoader.get_ability("ability_001")
	_assert(photo != null, "get_ability('ability_001') returned null")
	_assert(String(photo["kind"]) == "dps_multiplier", "ability_001.kind should be dps_multiplier")
	var click10: Variant = DataLoader.get_achievement("achievement_001")
	_assert(click10 != null, "get_achievement('achievement_001') returned null")

func _test_lookups_safe_on_miss() -> void:
	# Misses must return null, not crash.
	_assert(DataLoader.get_stage("nonexistent") == null, "stage miss should be null")
	_assert(DataLoader.get_upgrade_auto("auto_999") == null, "auto miss should be null")
	_assert(DataLoader.get_upgrade_click("click_999") == null, "click miss should be null")
	_assert(DataLoader.get_research("research_999") == null, "research miss should be null")
	_assert(DataLoader.get_ability("ability_999") == null, "ability miss should be null")
	_assert(DataLoader.get_achievement("achievement_999") == null, "achievement miss should be null")

func _test_stage_by_tier_helper() -> void:
	_assert(DataLoader.get_stage_by_tier(0) == null, "tier 0 should be null")
	_assert(DataLoader.get_stage_by_tier(31) == null, "tier 31 should be null")
	var s1: Variant = DataLoader.get_stage_by_tier(1)
	_assert(s1 != null and String(s1["id"]) == "stage_001", "tier 1 should be stage_001")
	var s30: Variant = DataLoader.get_stage_by_tier(30)
	_assert(s30 != null and String(s30["id"]) == "stage_030", "tier 30 should be stage_030")

# ----------------------------------------------------------------------------
# stage_visuals coverage (P2 cell-visuals work, mirrors HTML PR #30)
# ----------------------------------------------------------------------------

func _test_stage_visuals_present_for_every_stage() -> void:
	# Cross-table check: every stage must have a matching stage_visual.
	for s in DataLoader.stages:
		var sid: String = String(s["id"])
		var v: Variant = DataLoader.get_stage_visual(sid)
		_assert(v != null, "stage '%s' has no stage_visual entry" % sid)

func _test_stage_visuals_signature_allowlisted() -> void:
	for v in DataLoader.stage_visuals:
		var sig: String = String(v["signature"])
		_assert(
			sig in DataLoader.STAGE_VISUAL_SIGNATURES,
			"stage_visual '%s' has unknown signature '%s'" % [v["stage_id"], sig])

func _test_stage_visuals_shape_kind_allowlisted() -> void:
	for v in DataLoader.stage_visuals:
		var kind: String = String(v["shape_kind"])
		_assert(
			kind in DataLoader.STAGE_VISUAL_SHAPE_KINDS,
			"stage_visual '%s' has unknown shape_kind '%s'" % [v["stage_id"], kind])

func _test_stage_visuals_colors_are_hex() -> void:
	for v in DataLoader.stage_visuals:
		for k in ["color_membrane", "color_organ", "color_glow"]:
			var col_str: String = String(v[k])
			# Constructing Color from "#rrggbb" should not crash and should
			# yield a non-default Color (catches typos that parsed as black).
			var c := Color(col_str)
			# The hex regex is enforced at load time; here we just verify the
			# string round-trips cleanly into a Godot Color.
			_assert(
				col_str.length() == 7 and col_str.begins_with("#"),
				"stage_visual '%s' %s '%s' is not a 7-char '#rrggbb'" % [v["stage_id"], k, col_str])
			# All-zero color would mean the hex was unparseable.
			_assert(
				c.r + c.g + c.b > 0.0,
				"stage_visual '%s' %s parsed to all-black — likely invalid hex" % [v["stage_id"], k])

func _test_stage_visual_lookups() -> void:
	# By stage_id
	var v1: Variant = DataLoader.get_stage_visual("stage_001")
	_assert(v1 != null, "get_stage_visual('stage_001') returned null")
	_assert(String(v1["signature"]) == "plasma", "stage_001 signature should be 'plasma'")
	# By tier
	_assert(DataLoader.get_stage_visual_by_tier(0) == null, "tier 0 visual should be null")
	_assert(DataLoader.get_stage_visual_by_tier(31) == null, "tier 31 visual should be null")
	var v30: Variant = DataLoader.get_stage_visual_by_tier(30)
	_assert(v30 != null and String(v30["stage_id"]) == "stage_030", "tier 30 visual should be stage_030")
	# Miss
	_assert(DataLoader.get_stage_visual("nonexistent") == null, "stage_visual miss should be null")

# ----------------------------------------------------------------------------
# Tiny assertion helpers
# ----------------------------------------------------------------------------

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
	else:
		_failures.append(msg)

func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual == expected:
		_passes += 1
	else:
		_failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])

func _assert_no_duplicates(items: Array, label: String) -> void:
	var seen: Dictionary = {}
	for item in items:
		var id: String = String(item["id"])
		if seen.has(id):
			_failures.append("%s: duplicate id '%s'" % [label, id])
			return
		seen[id] = true
	_passes += 1

func _report() -> void:
	print("")
	print("================================================================")
	print("DataLoader tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
