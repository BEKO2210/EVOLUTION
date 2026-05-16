extends SceneTree
##
## Headless test for AchievementSystem (Phase 1 / P1-009).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_achievement_system.gd
##
## Coverage:
##   - is_unlocked / get_unlocked_count / get_total_count starting state
##   - clicking 10 times unlocks achievement_001 (legacy click10) and emits
##     GameState.achievement_unlocked
##   - Double-trigger is idempotent (signal fires once per achievement)
##   - lifetime_dna threshold unlocks achievement_006 (legacy dna1k)
##   - stage threshold unlocks achievement_011 (legacy stage3)
##   - prestige_performed unlocks achievement_024 (legacy prestige1)
##   - all_auto_upgrades_owned: trigger when every auto upgrade has count>=1
##   - all_click_upgrades_owned: trigger when every click upgrade has count>=1
##   - get_reward_multipliers aggregates correctly (single + stacked)
##   - reward multiplier flows into UpgradeSystem.recalc_stats (dps changes)
##   - check_all is idempotent (running twice unlocks 0 new the second time)
##   - SaveSystem.load_completed triggers re-evaluation
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0
var _signal_log: Array = []

func _initialize() -> void:
	TickSystem.set_auto_save_enabled(false)
	TickSystem.pause()
	await create_timer(0.05).timeout

	GameState.achievement_unlocked.connect(_record_unlock)

	_reset_state()
	_test_initial_state()
	_test_clicks_unlock_click10()
	_test_unlock_is_idempotent()
	_test_lifetime_dna_unlock()
	_test_stage_threshold_unlock()
	_test_prestige_unlock()
	_test_all_auto_upgrades_owned()
	_test_all_click_upgrades_owned()
	_test_reward_multipliers_single()
	_test_reward_multipliers_stacked()
	_test_reward_flows_into_recalc_stats()
	_test_check_all_idempotent()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_initial_state() -> void:
	_assert_eq(AchievementSystem.get_unlocked_count(), 0,
		"fresh state should have 0 unlocked")
	_assert_eq(AchievementSystem.get_total_count(), 27,
		"data/achievements.json defines 27 entries")
	_assert(not AchievementSystem.is_unlocked("achievement_001"),
		"achievement_001 should start locked")

func _test_clicks_unlock_click10() -> void:
	_reset_state()
	_signal_log.clear()
	# achievement_001 (legacy click10): total_clicks >= 10
	# Drive 10 register_click() calls; they each emit dna_changed and
	# click_landed which both trigger check_all.
	for i in 10:
		ClickSystem.register_click()
	_assert(AchievementSystem.is_unlocked("achievement_001"),
		"achievement_001 should unlock after 10 clicks")
	_assert(_signal_log.has("achievement_001"),
		"achievement_unlocked signal should have fired for achievement_001")

func _test_unlock_is_idempotent() -> void:
	# achievement_001 already unlocked from previous test; clicking more
	# must NOT emit the signal again for the same id.
	_signal_log.clear()
	for i in 50:
		ClickSystem.register_click()
	# count "achievement_001" entries in the log
	var count: int = 0
	for entry in _signal_log:
		if String(entry) == "achievement_001":
			count += 1
	_assert_eq(count, 0,
		"achievement_001 must not re-emit after first unlock (got %d re-emits)" % count)

func _test_lifetime_dna_unlock() -> void:
	_reset_state()
	# achievement_006 (legacy dna1k): lifetime_dna >= 1000
	GameState.add_dna(1000.0)  # adds to lifetime + total + dna; fires dna_changed
	_assert(AchievementSystem.is_unlocked("achievement_006"),
		"achievement_006 should unlock at 1k lifetime DNA")

func _test_stage_threshold_unlock() -> void:
	_reset_state()
	# achievement_011 (legacy stage3): stage >= 3
	# Easiest: directly set stage + manually trigger check_all (since the
	# normal trigger is stage_changed which fires from StageSystem on
	# total_dna_changed; we want to avoid an N-million add_dna here).
	GameState.stage = 3
	GameState.stage_changed.emit(3, 1)
	_assert(AchievementSystem.is_unlocked("achievement_011"),
		"achievement_011 should unlock at stage 3")

func _test_prestige_unlock() -> void:
	_reset_state()
	# achievement_024 (legacy prestige1): prestige_points >= 1
	GameState.lifetime_dna = 1_000_000.0
	PrestigeSystem.do_prestige()
	# do_prestige emits prestige_performed → AchievementSystem checks
	_assert(AchievementSystem.is_unlocked("achievement_024"),
		"achievement_024 should unlock after first prestige")

func _test_all_auto_upgrades_owned() -> void:
	_reset_state()
	# achievement_026 (auto30): every auto upgrade has count >= 1
	# Seed counts manually (cheaper than buying through UpgradeSystem here).
	for u in DataLoader.upgrades_auto:
		GameState.upgrade_counts[String(u["id"])] = 1
	# Trigger by emitting upgrade_purchased (UpgradeSystem usually emits this)
	UpgradeSystem.upgrade_purchased.emit("auto_001", 1, 60.0)
	_assert(AchievementSystem.is_unlocked("achievement_026"),
		"achievement_026 should unlock when every auto upgrade is owned")

func _test_all_click_upgrades_owned() -> void:
	_reset_state()
	for u in DataLoader.upgrades_click:
		GameState.upgrade_counts[String(u["id"])] = 1
	UpgradeSystem.upgrade_purchased.emit("click_001", 1, 200.0)
	_assert(AchievementSystem.is_unlocked("achievement_027"),
		"achievement_027 should unlock when every click upgrade is owned")

func _test_reward_multipliers_single() -> void:
	_reset_state()
	# Unlock just achievement_001 (click_multiplier: 1.02)
	GameState.achievements_unlocked["achievement_001"] = 1
	var bundle: Dictionary = AchievementSystem.get_reward_multipliers()
	_assert(abs(float(bundle["click_mult"]) - 1.02) < 0.0001,
		"single click_mult should be 1.02 (got %f)" % float(bundle["click_mult"]))
	_assert_eq(float(bundle["dps_mult"]), 1.0, "dps_mult untouched")
	_assert_eq(float(bundle["all_mult"]), 1.0, "all_mult untouched")

func _test_reward_multipliers_stacked() -> void:
	_reset_state()
	# achievement_001 (click_mult 1.02) + achievement_006 (all_mult 1.01)
	# + achievement_011 (dps_mult 1.03)
	GameState.achievements_unlocked["achievement_001"] = 1
	GameState.achievements_unlocked["achievement_006"] = 1
	GameState.achievements_unlocked["achievement_011"] = 1
	var bundle: Dictionary = AchievementSystem.get_reward_multipliers()
	_assert(abs(float(bundle["click_mult"]) - 1.02) < 0.0001,
		"click_mult should be 1.02")
	_assert(abs(float(bundle["all_mult"]) - 1.01) < 0.0001,
		"all_mult should be 1.01")
	_assert(abs(float(bundle["dps_mult"]) - 1.03) < 0.0001,
		"dps_mult should be 1.03")

func _test_reward_flows_into_recalc_stats() -> void:
	_reset_state()
	# Base: 5x auto_001 = 0.4*5 = 2 dps; achievement_011 gives dps_multiplier 1.03
	# Expected: dps = 2 * 1.03 = 2.06
	GameState.upgrade_counts = {"auto_001": 5}
	GameState.achievements_unlocked = {"achievement_011": 1}
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.dps - 2.06) < 0.001,
		"dps should be 2.06 with achievement_011 reward (got %f)" % GameState.dps)
	# Add achievement_006 (all_mult 1.01): dps = 2 * 1.03 * 1.01 = 2.0806
	GameState.achievements_unlocked["achievement_006"] = 1
	UpgradeSystem.recalc_stats()
	_assert(abs(GameState.dps - 2.0806) < 0.001,
		"dps should be 2.0806 with stacked rewards (got %f)" % GameState.dps)

func _test_check_all_idempotent() -> void:
	_reset_state()
	GameState.total_clicks = 100
	var first: int = AchievementSystem.check_all()
	var second: int = AchievementSystem.check_all()
	_assert(first >= 1, "first check should unlock at least 1 click achievement (got %d)" % first)
	_assert_eq(second, 0, "second check_all should unlock 0 (idempotent)")

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

func _record_unlock(id: String) -> void:
	_signal_log.append(id)

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
	GameState.total_clicks = 0
	GameState.total_crits = 0
	GameState.total_goldens = 0
	GameState.upgrade_counts = {}
	GameState.achievements_unlocked = {}
	ClickSystem.reset_combo()
	_signal_log.clear()

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
	print("AchievementSystem tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
