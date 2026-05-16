extends SceneTree
##
## Headless test for StageSystem (Phase 1 / P1-007).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_stage_system.gd
##
## Coverage:
##   - get_stage_for_total_dna pure function across known thresholds
##   - get_stage_for_total_dna saturates at max tier
##   - get_threshold_for_tier returns correct values + INF for out-of-range
##   - has_stage true/false
##   - add_dna past a threshold emits stage_changed once
##   - add_dna NOT crossing threshold does NOT emit
##   - jumping multiple thresholds emits ONE signal with destination
##   - spend_dna (dna goes down) does NOT reduce stage
##   - reset (prestige) rolls stage back to 1
##   - recompute_stage is idempotent
##   - recompute_stage lifts stage if save loaded inconsistent state
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	TickSystem.set_auto_save_enabled(false)
	TickSystem.pause()  # no auto DPS ticks
	await create_timer(0.05).timeout

	_reset_state()

	_test_get_stage_pure_function()
	_test_saturate_at_max_tier()
	_test_threshold_helpers()
	_test_has_stage()
	_test_add_dna_crosses_threshold_emits_once()
	_test_add_dna_below_threshold_no_emit()
	_test_multiple_thresholds_single_signal()
	_test_spend_dna_does_not_reduce_stage()
	_test_reset_rolls_stage_back_to_1()
	_test_recompute_stage_idempotent()
	_test_recompute_stage_lifts_inconsistent_save()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_get_stage_pure_function() -> void:
	# stage_001 starts at 0, stage_002 at 1000, stage_003 at 25000
	_assert_eq(StageSystem.get_stage_for_total_dna(0.0), 1, "stage at 0 DNA")
	_assert_eq(StageSystem.get_stage_for_total_dna(999.0), 1, "stage just under 1k DNA")
	_assert_eq(StageSystem.get_stage_for_total_dna(1000.0), 2, "stage at exactly 1k DNA")
	_assert_eq(StageSystem.get_stage_for_total_dna(24999.0), 2, "stage just under 25k DNA")
	_assert_eq(StageSystem.get_stage_for_total_dna(25000.0), 3, "stage at exactly 25k DNA")
	_assert_eq(StageSystem.get_stage_for_total_dna(599999.0), 3, "stage just under 600k DNA")
	_assert_eq(StageSystem.get_stage_for_total_dna(600000.0), 4, "stage at exactly 600k DNA")

func _test_saturate_at_max_tier() -> void:
	# stage 30 threshold is 1.5e42 — any larger total_dna stays at 30.
	_assert_eq(StageSystem.get_stage_for_total_dna(1e50), 30, "huge DNA caps at tier 30")
	_assert_eq(StageSystem.get_stage_for_total_dna(1e60), 30, "even bigger DNA still tier 30")

func _test_threshold_helpers() -> void:
	_assert_eq(StageSystem.get_threshold_for_tier(1), 0.0, "tier 1 threshold")
	_assert_eq(StageSystem.get_threshold_for_tier(2), 1000.0, "tier 2 threshold")
	_assert_eq(StageSystem.get_threshold_for_tier(3), 25000.0, "tier 3 threshold")
	_assert(is_inf(StageSystem.get_threshold_for_tier(31)), "tier 31 should return INF (out of range)")
	_assert(is_inf(StageSystem.get_threshold_for_tier(0)), "tier 0 should return INF (out of range)")

func _test_has_stage() -> void:
	_assert(StageSystem.has_stage(1), "tier 1 exists")
	_assert(StageSystem.has_stage(30), "tier 30 exists")
	_assert(not StageSystem.has_stage(31), "tier 31 does not exist")
	_assert(not StageSystem.has_stage(0), "tier 0 does not exist")

func _test_add_dna_crosses_threshold_emits_once() -> void:
	_reset_state()
	var captured: Array = []
	var capture := func(new_stage: int, old_stage: int) -> void:
		captured.append({ "new": new_stage, "old": old_stage })
	GameState.stage_changed.connect(capture)
	# Push total_dna from 0 to just past 1000 -> stage 2
	GameState.add_dna(1000.0)
	_assert_eq(captured.size(), 1, "exactly one stage_changed signal")
	if captured.size() == 1:
		_assert_eq(int(captured[0]["new"]), 2, "new_stage should be 2")
		_assert_eq(int(captured[0]["old"]), 1, "old_stage should be 1")
	_assert_eq(GameState.stage, 2, "GameState.stage updated to 2")
	GameState.stage_changed.disconnect(capture)

func _test_add_dna_below_threshold_no_emit() -> void:
	_reset_state()
	var emitted: int = 0
	var capture := func(_n: int, _o: int) -> void:
		emitted += 1
	GameState.stage_changed.connect(capture)
	# Add 500 -> still tier 1
	GameState.add_dna(500.0)
	_assert_eq(emitted, 0, "no signal when threshold not crossed")
	_assert_eq(GameState.stage, 1, "stage stays at 1")
	GameState.stage_changed.disconnect(capture)

func _test_multiple_thresholds_single_signal() -> void:
	_reset_state()
	var captured: Array = []
	var capture := func(n: int, o: int) -> void:
		captured.append({ "new": n, "old": o })
	GameState.stage_changed.connect(capture)
	# Jump from total_dna=0 to total_dna=1M in one add (crosses tiers 2,3,4,5)
	GameState.add_dna(1_000_000.0)
	_assert_eq(captured.size(), 1,
		"single add_dna crossing many tiers should emit ONE signal (got %d)" % captured.size())
	if captured.size() == 1:
		# 1M >= 600k = tier 4 threshold; <15M = tier 5; so we expect 4.
		_assert_eq(int(captured[0]["new"]), 4, "new_stage should be 4 (1M DNA)")
		_assert_eq(int(captured[0]["old"]), 1, "old_stage should be 1")
	GameState.stage_changed.disconnect(capture)

func _test_spend_dna_does_not_reduce_stage() -> void:
	_reset_state()
	GameState.add_dna(25000.0)  # tier 3
	_assert_eq(GameState.stage, 3, "should be tier 3 after 25k DNA")
	var captured: int = 0
	var capture := func(_n: int, _o: int) -> void:
		captured += 1
	GameState.stage_changed.connect(capture)
	GameState.spend_dna(20000.0)  # current dna goes down
	_assert_eq(captured, 0, "spend_dna should NOT emit stage_changed")
	_assert_eq(GameState.stage, 3, "stage should stay at 3 after spending")
	GameState.stage_changed.disconnect(capture)

func _test_reset_rolls_stage_back_to_1() -> void:
	_reset_state()
	GameState.add_dna(600_000.0)  # tier 4
	_assert_eq(GameState.stage, 4, "should be tier 4 before reset")
	GameState.reset_for_prestige()  # zeroes total_dna + sets stage=1 + emits state_reset
	_assert_eq(GameState.stage, 1, "stage should be 1 after prestige reset")
	_assert_eq(GameState.total_dna, 0.0, "total_dna should be 0 after prestige reset")

func _test_recompute_stage_idempotent() -> void:
	_reset_state()
	GameState.add_dna(1000.0)  # tier 2
	var captured: int = 0
	var capture := func(_n: int, _o: int) -> void:
		captured += 1
	GameState.stage_changed.connect(capture)
	StageSystem.recompute_stage()
	StageSystem.recompute_stage()
	StageSystem.recompute_stage()
	_assert_eq(captured, 0, "recompute_stage on already-correct stage emits nothing")
	GameState.stage_changed.disconnect(capture)

func _test_recompute_stage_lifts_inconsistent_save() -> void:
	# Simulate "loaded save where total_dna is high but stage was wrongly 1"
	_reset_state()
	GameState.total_dna = 1_000_000.0  # would be tier 4
	GameState.stage = 1                # but stage is stale
	var captured: Array = []
	var capture := func(n: int, o: int) -> void:
		captured.append({ "new": n, "old": o })
	GameState.stage_changed.connect(capture)
	StageSystem.recompute_stage()
	_assert_eq(captured.size(), 1, "recompute should fire one signal for inconsistent save")
	if captured.size() == 1:
		_assert_eq(int(captured[0]["new"]), 4, "should jump to tier 4")
		_assert_eq(int(captured[0]["old"]), 1, "from tier 1")
	_assert_eq(GameState.stage, 4, "stage now reflects total_dna")
	GameState.stage_changed.disconnect(capture)

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

func _reset_state() -> void:
	GameState.dna = 0.0
	GameState.total_dna = 0.0
	GameState.lifetime_dna = 0.0
	GameState.click_power = 1.0
	GameState.dps = 0.0
	GameState.stage = 1
	GameState.prestige_points = 0
	GameState.prestige_multiplier = 1.0
	GameState.upgrade_counts = {}
	GameState.achievements_unlocked = {}

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

func _report() -> void:
	print("")
	print("================================================================")
	print("StageSystem tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
