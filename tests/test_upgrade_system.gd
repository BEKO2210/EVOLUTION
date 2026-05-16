extends SceneTree
##
## Headless test for UpgradeSystem (Phase 1 / P1-006).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_upgrade_system.gd
##
## Coverage:
##   - get_count returns 0 for un-bought upgrades
##   - get_cost matches cost_base * 1.15^count formula
##   - get_bulk_cost matches geometric-series sum
##   - get_max_affordable for a known DNA balance
##   - buy() succeeds when affordable + fails when not
##   - buy() deducts DNA and increments count
##   - buy_bulk() buys N in one transaction
##   - buy_max() buys as many as affordable
##   - milestone_crossed signal fires at 10/25/50/100
##   - get_milestone_multiplier is 1/2/4/8/16 across thresholds
##   - recalc_stats updates GameState.dps for auto upgrades
##   - recalc_stats updates GameState.click_power for click upgrades
##   - milestone doubling is reflected in dps
##   - upgrade_purchased signal fires with new_count + total_cost
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

# Test fixture: keep a known starting state so each test is hermetic.
func _initialize() -> void:
	# Stop auto-DPS ticks so we control GameState.dna entirely.
	TickSystem.set_auto_save_enabled(false)
	TickSystem.pause()
	# Wait one frame so any in-flight signals from autoload _ready have drained.
	await create_timer(0.05).timeout

	_reset_game_state()

	_test_get_count_default_zero()
	_test_get_cost_formula()
	_test_get_bulk_cost_formula()
	_test_get_max_affordable()
	_test_buy_succeeds_and_mutates()
	_test_buy_fails_when_unaffordable()
	_test_buy_bulk()
	_test_buy_max()
	_test_milestone_multiplier_table()
	_test_milestone_signal_fires_at_thresholds()
	_test_recalc_stats_dps()
	_test_recalc_stats_click_power()
	_test_recalc_stats_milestone_doubling()
	_test_upgrade_purchased_signal()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_get_count_default_zero() -> void:
	_reset_game_state()
	_assert(UpgradeSystem.get_count("auto_001") == 0, "auto_001 count should default to 0")
	_assert(UpgradeSystem.get_count("click_001") == 0, "click_001 count should default to 0")
	_assert(UpgradeSystem.get_count("nonexistent") == 0, "nonexistent upgrade count should be 0")

func _test_get_cost_formula() -> void:
	_reset_game_state()
	# auto_001: cost_base = 60, cost_growth = 1.15
	# count=0 -> cost = 60 * 1.15^0 = 60
	# count=5 -> cost = 60 * 1.15^5 ≈ 60 * 2.0114 ≈ 120.68
	var c0: float = UpgradeSystem.get_cost("auto_001")
	_assert(abs(c0 - 60.0) < 0.001, "auto_001 cost at count=0 should be 60 (got %f)" % c0)

	GameState.upgrade_counts["auto_001"] = 5
	var c5: float = UpgradeSystem.get_cost("auto_001")
	var expected: float = 60.0 * pow(1.15, 5)
	_assert(abs(c5 - expected) < 0.001, "auto_001 cost at count=5 should be %f (got %f)" % [expected, c5])

	# Unknown id returns 0
	_assert(UpgradeSystem.get_cost("nonexistent") == 0.0, "unknown upgrade should return 0 cost")

func _test_get_bulk_cost_formula() -> void:
	_reset_game_state()
	# Sum of 10 purchases starting from count=0:
	# cost_base * (g^10 - 1) / (g - 1)
	var expected: float = 60.0 * (pow(1.15, 10) - 1.0) / (1.15 - 1.0)
	var got: float = UpgradeSystem.get_bulk_cost("auto_001", 10)
	_assert(abs(got - expected) < 0.001, "bulk cost 10 of auto_001 should be %f (got %f)" % [expected, got])
	_assert(UpgradeSystem.get_bulk_cost("auto_001", 0) == 0.0, "bulk cost of 0 should be 0")
	_assert(UpgradeSystem.get_bulk_cost("auto_001", -3) == 0.0, "bulk cost of negative should be 0")

func _test_get_max_affordable() -> void:
	_reset_game_state()
	GameState.dna = 60.0
	_assert(UpgradeSystem.get_max_affordable("auto_001") == 1,
		"max affordable with exactly 60 DNA should be 1")
	GameState.dna = 59.0
	_assert(UpgradeSystem.get_max_affordable("auto_001") == 0,
		"max affordable with 59 DNA should be 0")
	# With 1000 DNA we can afford 10 of auto_001 since bulk cost = 1218
	# So max affordable is what fits under 1000:
	GameState.dna = 1218.94  # ~bulk cost of 10
	var got: int = UpgradeSystem.get_max_affordable("auto_001")
	_assert(got >= 9 and got <= 10,
		"max affordable with ~1219 DNA should be 9 or 10 (got %d)" % got)

func _test_buy_succeeds_and_mutates() -> void:
	_reset_game_state()
	GameState.dna = 200.0
	var ok: bool = UpgradeSystem.buy("auto_001")
	_assert(ok, "buy auto_001 with 200 DNA should succeed")
	_assert(UpgradeSystem.get_count("auto_001") == 1, "count should be 1 after buy")
	_assert(abs(GameState.dna - 140.0) < 0.001, "DNA should be 140 after spending 60 (got %f)" % GameState.dna)

func _test_buy_fails_when_unaffordable() -> void:
	_reset_game_state()
	GameState.dna = 5.0
	var ok: bool = UpgradeSystem.buy("auto_001")
	_assert(not ok, "buy with insufficient DNA should fail")
	_assert(UpgradeSystem.get_count("auto_001") == 0, "count should stay 0 on failed buy")
	_assert(GameState.dna == 5.0, "DNA should be unchanged on failed buy")

func _test_buy_bulk() -> void:
	_reset_game_state()
	var bulk_cost: float = UpgradeSystem.get_bulk_cost("auto_001", 5)
	GameState.dna = bulk_cost + 100.0
	var dna_before: float = GameState.dna
	var ok: bool = UpgradeSystem.buy_bulk("auto_001", 5)
	_assert(ok, "buy_bulk(5) with sufficient DNA should succeed")
	_assert(UpgradeSystem.get_count("auto_001") == 5, "count should be 5 after buy_bulk(5)")
	_assert(abs(GameState.dna - (dna_before - bulk_cost)) < 0.001,
		"DNA should be reduced by bulk_cost")

func _test_buy_max() -> void:
	_reset_game_state()
	GameState.dna = 500.0
	var bought: int = UpgradeSystem.buy_max("auto_001")
	_assert(bought >= 1, "buy_max with 500 DNA should buy at least 1 (got %d)" % bought)
	_assert(UpgradeSystem.get_count("auto_001") == bought,
		"count should equal buy_max return value")
	# After buy_max, you should NOT be able to afford one more of the same upgrade
	# (we bought exactly to the affordable limit).
	_assert(not UpgradeSystem.can_afford("auto_001"),
		"after buy_max, can_afford should be false")

func _test_milestone_multiplier_table() -> void:
	# Across the four thresholds the multiplier is 1, 2, 4, 8, 16.
	_assert(UpgradeSystem.get_milestone_multiplier(0) == 1.0, "mult(0) should be 1")
	_assert(UpgradeSystem.get_milestone_multiplier(9) == 1.0, "mult(9) should be 1")
	_assert(UpgradeSystem.get_milestone_multiplier(10) == 2.0, "mult(10) should be 2")
	_assert(UpgradeSystem.get_milestone_multiplier(24) == 2.0, "mult(24) should be 2")
	_assert(UpgradeSystem.get_milestone_multiplier(25) == 4.0, "mult(25) should be 4")
	_assert(UpgradeSystem.get_milestone_multiplier(49) == 4.0, "mult(49) should be 4")
	_assert(UpgradeSystem.get_milestone_multiplier(50) == 8.0, "mult(50) should be 8")
	_assert(UpgradeSystem.get_milestone_multiplier(99) == 8.0, "mult(99) should be 8")
	_assert(UpgradeSystem.get_milestone_multiplier(100) == 16.0, "mult(100) should be 16")
	_assert(UpgradeSystem.get_milestone_multiplier(500) == 16.0, "mult(500) should still be 16")

func _test_milestone_signal_fires_at_thresholds() -> void:
	_reset_game_state()
	var crossings: Array = []
	var capture := func(upgrade_id: String, ms: int, new_count: int) -> void:
		crossings.append({ "id": upgrade_id, "ms": ms, "n": new_count })
	UpgradeSystem.milestone_crossed.connect(capture)
	# Jump count to 9 by giving lots of DNA and buying one at a time would be
	# slow; instead seed count to 9 and buy 1 -> should cross 10.
	GameState.upgrade_counts["auto_001"] = 9
	GameState.dna = 1e18
	UpgradeSystem.buy("auto_001")
	_assert(crossings.size() == 1, "expected 1 milestone crossing, got %d" % crossings.size())
	if crossings.size() == 1:
		_assert(int(crossings[0]["ms"]) == 10, "should cross threshold 10")
	# Now jump from 9 to 26 in one bulk buy -> should cross BOTH 10 and 25
	crossings.clear()
	GameState.upgrade_counts["auto_001"] = 9
	GameState.dna = 1e18
	UpgradeSystem.buy_bulk("auto_001", 17)  # 9 + 17 = 26 >= 25
	_assert(crossings.size() == 2,
		"bulk buy across two milestones should fire 2 signals (got %d)" % crossings.size())
	UpgradeSystem.milestone_crossed.disconnect(capture)

func _test_recalc_stats_dps() -> void:
	_reset_game_state()
	# auto_001 base dps = 0.4; count = 5 -> dps = 0.4 * 5 = 2.0 (no milestone yet)
	GameState.upgrade_counts["auto_001"] = 5
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.dps - 2.0) < 0.001,
		"dps with 5x auto_001 should be 2.0 (got %f)" % GameState.dps)
	# Add 3x auto_002 (base 1.8): dps += 1.8 * 3 = 5.4 -> total 7.4
	GameState.upgrade_counts["auto_002"] = 3
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.dps - (2.0 + 5.4)) < 0.001,
		"dps with 5x auto_001 + 3x auto_002 should be 7.4 (got %f)" % GameState.dps)

func _test_recalc_stats_click_power() -> void:
	_reset_game_state()
	# click_001 base = 1; count = 3 -> click_power = 1 + 1*3 = 4
	GameState.upgrade_counts["click_001"] = 3
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.click_power - 4.0) < 0.001,
		"click_power with 3x click_001 should be 4.0 (got %f)" % GameState.click_power)

func _test_recalc_stats_milestone_doubling() -> void:
	_reset_game_state()
	# At count 10, dps is doubled. auto_001: 0.4 * 10 * 2 = 8.0
	GameState.upgrade_counts["auto_001"] = 10
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.dps - 8.0) < 0.001,
		"dps with 10x auto_001 should be 8.0 with milestone doubling (got %f)" % GameState.dps)
	# At count 100, ×16 doubling: 0.4 * 100 * 16 = 640
	GameState.upgrade_counts["auto_001"] = 100
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.dps - 640.0) < 0.001,
		"dps with 100x auto_001 should be 640.0 with x16 milestone (got %f)" % GameState.dps)

func _test_upgrade_purchased_signal() -> void:
	_reset_game_state()
	var captured: Dictionary = {}
	var capture := func(upgrade_id: String, new_count: int, total_cost: float) -> void:
		captured = { "id": upgrade_id, "n": new_count, "cost": total_cost }
	UpgradeSystem.upgrade_purchased.connect(capture)
	GameState.dna = 300.0
	UpgradeSystem.buy("auto_001")
	_assert(String(captured.get("id", "")) == "auto_001", "signal id mismatch")
	_assert(int(captured.get("n", 0)) == 1, "signal new_count mismatch")
	_assert(abs(float(captured.get("cost", 0.0)) - 60.0) < 0.001,
		"signal total_cost should be 60 (got %f)" % float(captured.get("cost", 0.0)))
	UpgradeSystem.upgrade_purchased.disconnect(capture)

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

func _reset_game_state() -> void:
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

func _report() -> void:
	print("")
	print("================================================================")
	print("UpgradeSystem tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
