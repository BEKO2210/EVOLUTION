extends SceneTree
##
## Headless test for PrestigeSystem (Phase 1 / P1-008).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_prestige_system.gd
##
## Coverage:
##   - can_prestige is false below the lifetime_dna threshold
##   - can_prestige is true at exactly threshold and above
##   - get_evolution_points_available formula (1 EP at 1M, 10 EP at 100M, ...)
##   - get_evolution_points_available subtracts already-claimed points
##   - get_current_multiplier returns 1.10^prestige_points
##   - get_next_multiplier_after_prestige predicts the value after claiming
##   - get_lifetime_dna_needed_for_total_points inverts the EP formula
##   - do_prestige returns 0 when ineligible (no side effects)
##   - do_prestige with 1M lifetime: gains 1 EP, sets multiplier to 1.10
##   - do_prestige wipes dna/total_dna/stage/upgrade_counts/divisions
##   - do_prestige PRESERVES lifetime_dna and prestige_points (cumulative)
##   - prestige_multiplier compounds across consecutive prestiges
##   - UpgradeSystem.recalc_stats applies prestige_multiplier to dps + click
##   - state_reset triggers UpgradeSystem to recalc (post-prestige dps reflects new mult)
##   - recalc_multiplier is idempotent and corrects stale multiplier
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	TickSystem.set_auto_save_enabled(false)
	TickSystem.pause()
	await create_timer(0.05).timeout

	_reset_state()

	_test_can_prestige_threshold()
	_test_ep_formula()
	_test_ep_subtracts_claimed_points()
	_test_current_multiplier()
	_test_next_multiplier_prediction()
	_test_lifetime_inverse_helper()
	_test_do_prestige_ineligible_no_side_effects()
	_test_do_prestige_single_run()
	_test_do_prestige_wipes_run_state()
	_test_do_prestige_preserves_meta()
	_test_multiplier_compounds_across_prestiges()
	_test_recalc_stats_applies_prestige_multiplier()
	_test_state_reset_triggers_upgrade_recalc()
	_test_recalc_multiplier_idempotent_and_self_healing()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_can_prestige_threshold() -> void:
	_reset_state()
	_assert(not PrestigeSystem.can_prestige(), "should not be eligible at 0 lifetime DNA")
	GameState.lifetime_dna = 999_999.0
	_assert(not PrestigeSystem.can_prestige(), "should not be eligible just under 1M")
	GameState.lifetime_dna = 1_000_000.0
	_assert(PrestigeSystem.can_prestige(), "should be eligible at exactly 1M")
	GameState.lifetime_dna = 50_000_000.0
	_assert(PrestigeSystem.can_prestige(), "should be eligible at 50M")

func _test_ep_formula() -> void:
	_reset_state()
	GameState.lifetime_dna = 0.0
	_assert_eq(PrestigeSystem.get_evolution_points_available(), 0, "EP at 0 DNA")
	GameState.lifetime_dna = 1_000_000.0   # sqrt(1) = 1
	_assert_eq(PrestigeSystem.get_evolution_points_available(), 1, "EP at exactly 1M")
	GameState.lifetime_dna = 4_000_000.0   # sqrt(4) = 2
	_assert_eq(PrestigeSystem.get_evolution_points_available(), 2, "EP at 4M")
	GameState.lifetime_dna = 100_000_000.0 # sqrt(100) = 10
	_assert_eq(PrestigeSystem.get_evolution_points_available(), 10, "EP at 100M")
	GameState.lifetime_dna = 1_000_000_000.0  # sqrt(1000) ~ 31.6 -> floor 31
	_assert_eq(PrestigeSystem.get_evolution_points_available(), 31, "EP at 1B")

func _test_ep_subtracts_claimed_points() -> void:
	_reset_state()
	GameState.lifetime_dna = 100_000_000.0
	GameState.prestige_points = 3
	# floor(sqrt(100M/1M)) = 10; minus 3 already claimed = 7 available
	_assert_eq(PrestigeSystem.get_evolution_points_available(), 7,
		"7 EP available (10 earned - 3 claimed)")
	GameState.prestige_points = 10
	_assert_eq(PrestigeSystem.get_evolution_points_available(), 0,
		"0 EP available (10 earned - 10 claimed)")
	GameState.prestige_points = 99  # somehow claimed more than earned
	_assert_eq(PrestigeSystem.get_evolution_points_available(), 0,
		"floor at 0, never negative")

func _test_current_multiplier() -> void:
	_reset_state()
	GameState.prestige_points = 0
	PrestigeSystem.recalc_multiplier()
	_assert(abs(PrestigeSystem.get_current_multiplier() - 1.0) < 0.0001,
		"multiplier at 0 points should be 1.0")
	GameState.prestige_points = 1
	PrestigeSystem.recalc_multiplier()
	_assert(abs(PrestigeSystem.get_current_multiplier() - 1.10) < 0.0001,
		"multiplier at 1 point should be 1.10")
	GameState.prestige_points = 10
	PrestigeSystem.recalc_multiplier()
	# 1.10^10 ≈ 2.5937
	_assert(abs(PrestigeSystem.get_current_multiplier() - 2.5937) < 0.001,
		"multiplier at 10 points should be ~2.5937 (got %f)" % PrestigeSystem.get_current_multiplier())

func _test_next_multiplier_prediction() -> void:
	_reset_state()
	GameState.lifetime_dna = 100_000_000.0  # 10 EP available
	# After prestige, total points = 10, mult = 1.10^10 ≈ 2.5937
	var predicted: float = PrestigeSystem.get_next_multiplier_after_prestige()
	_assert(abs(predicted - 2.5937) < 0.001,
		"next mult prediction at 100M lifetime should be ~2.5937 (got %f)" % predicted)

func _test_lifetime_inverse_helper() -> void:
	_reset_state()
	_assert_eq(PrestigeSystem.get_lifetime_dna_needed_for_total_points(0), 0.0,
		"0 points needs 0 DNA")
	_assert_eq(PrestigeSystem.get_lifetime_dna_needed_for_total_points(1), 1_000_000.0,
		"1 point needs 1M DNA")
	_assert_eq(PrestigeSystem.get_lifetime_dna_needed_for_total_points(10), 100_000_000.0,
		"10 points needs 100M DNA")

func _test_do_prestige_ineligible_no_side_effects() -> void:
	_reset_state()
	GameState.lifetime_dna = 500_000.0  # below 1M
	GameState.dna = 12345.0
	GameState.total_dna = 12345.0
	GameState.stage = 3
	var gained: int = PrestigeSystem.do_prestige()
	_assert_eq(gained, 0, "ineligible do_prestige should return 0")
	_assert_eq(GameState.dna, 12345.0, "dna unchanged on ineligible prestige")
	_assert_eq(GameState.stage, 3, "stage unchanged on ineligible prestige")
	_assert_eq(GameState.prestige_points, 0, "prestige_points unchanged")

func _test_do_prestige_single_run() -> void:
	_reset_state()
	GameState.lifetime_dna = 1_000_000.0
	var gained: int = PrestigeSystem.do_prestige()
	_assert_eq(gained, 1, "do_prestige at 1M should gain 1 EP")
	_assert_eq(GameState.prestige_points, 1, "prestige_points should be 1")
	_assert(abs(GameState.prestige_multiplier - 1.10) < 0.0001,
		"multiplier should be 1.10 after first prestige")

func _test_do_prestige_wipes_run_state() -> void:
	_reset_state()
	GameState.lifetime_dna = 100_000_000.0
	GameState.dna = 5_000_000.0
	GameState.total_dna = 100_000_000.0
	GameState.stage = 7
	GameState.upgrade_counts = {"auto_001": 50, "click_001": 12}
	GameState.divisions = 3
	PrestigeSystem.do_prestige()
	_assert_eq(GameState.dna, 0.0, "dna wiped")
	_assert_eq(GameState.total_dna, 0.0, "total_dna wiped")
	_assert_eq(GameState.stage, 1, "stage back to 1")
	_assert(GameState.upgrade_counts.is_empty(), "upgrade_counts wiped")
	_assert_eq(GameState.divisions, 0, "divisions wiped")

func _test_do_prestige_preserves_meta() -> void:
	_reset_state()
	GameState.lifetime_dna = 100_000_000.0
	PrestigeSystem.do_prestige()
	_assert(GameState.lifetime_dna == 100_000_000.0,
		"lifetime_dna preserved across prestige (it's the EP currency)")
	_assert(GameState.prestige_points >= 1, "prestige_points preserved")

func _test_multiplier_compounds_across_prestiges() -> void:
	_reset_state()
	# Each prestige needs proportionally more lifetime DNA. To get 2 EP total
	# the player needs 4M lifetime (sqrt(4M/1M)=2). To get 3 EP total they
	# need 9M (sqrt(9M/1M)=3). We simulate three sequential prestiges by
	# bumping lifetime_dna between each call.
	GameState.lifetime_dna = 4_000_000.0  # supports up to 2 EP total
	PrestigeSystem.do_prestige()  # gains 2 EP
	_assert_eq(GameState.prestige_points, 2, "after first prestige: 2 points")
	_assert(abs(GameState.prestige_multiplier - pow(1.10, 2)) < 0.0001,
		"mult should be 1.10^2 = 1.21")
	# Bump lifetime to 9M -> total EP = 3, already claimed 2 -> 1 more
	GameState.lifetime_dna = 9_000_000.0
	PrestigeSystem.do_prestige()  # gains 1 more EP -> total 3
	_assert_eq(GameState.prestige_points, 3, "after second prestige: 3 points")
	_assert(abs(GameState.prestige_multiplier - pow(1.10, 3)) < 0.0001,
		"mult should be 1.10^3 ≈ 1.331")

func _test_recalc_stats_applies_prestige_multiplier() -> void:
	_reset_state()
	# 5x auto_001 = 0.4*5 = 2 dps base; prestige mult x1.10 -> 2.20 dps
	GameState.upgrade_counts = {"auto_001": 5}
	GameState.prestige_points = 1
	PrestigeSystem.recalc_multiplier()
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.dps - 2.2) < 0.001,
		"dps with 5x auto_001 + 1 prestige should be 2.2 (got %f)" % GameState.dps)

	# click_001 base 1; 3 of them = click_power = (1 + 3) * 1.10 = 4.4
	GameState.upgrade_counts = {"click_001": 3}
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.click_power - 4.4) < 0.001,
		"click_power with 3x click_001 + 1 prestige should be 4.4 (got %f)" % GameState.click_power)

func _test_state_reset_triggers_upgrade_recalc() -> void:
	_reset_state()
	# Pre-prestige: own upgrades, dps > 0
	GameState.lifetime_dna = 1_000_000.0
	GameState.upgrade_counts = {"auto_001": 10}  # milestone => 0.4*10*2 = 8 dps
	UpgradeSystem.recalc_stats()
	_assert(GameState.dps == 8.0, "pre-prestige dps should be 8")
	# Prestige: upgrades wiped, new multiplier 1.10
	PrestigeSystem.do_prestige()
	# UpgradeSystem._on_state_reset should have run recalc_stats; dps now 0
	_assert_eq(GameState.dps, 0.0, "dps should be 0 after prestige (no upgrades)")
	# click_power should be 1.0 base * 1.10 multiplier = 1.10
	_assert(abs(GameState.click_power - 1.10) < 0.001,
		"click_power post-prestige should be 1.10 (base * mult), got %f" % GameState.click_power)

func _test_recalc_multiplier_idempotent_and_self_healing() -> void:
	_reset_state()
	GameState.prestige_points = 4
	GameState.prestige_multiplier = 999.0  # corrupted / stale
	PrestigeSystem.recalc_multiplier()
	# 1.10^4 = 1.4641
	_assert(abs(GameState.prestige_multiplier - pow(1.10, 4)) < 0.0001,
		"recalc should heal a stale multiplier to 1.4641 (got %f)" % GameState.prestige_multiplier)
	# Calling again does nothing.
	PrestigeSystem.recalc_multiplier()
	_assert(abs(GameState.prestige_multiplier - pow(1.10, 4)) < 0.0001,
		"recalc is idempotent")

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
	GameState.divisions = 0
	GameState.prestige_points = 0
	GameState.prestige_multiplier = 1.0
	GameState.upgrade_counts = {}

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
	print("PrestigeSystem tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
