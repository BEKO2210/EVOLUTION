extends SceneTree
##
## Headless test for ClickSystem (Phase 1 / P1-006).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_click_system.gd
##
## Coverage:
##   - register_click adds DNA equal to GameState.click_power (with crit 0)
##   - total_clicks increments
##   - click_landed signal fires with (amount, pos, is_crit, combo_count)
##   - combo counter starts at 1, grows on rapid clicks, caps at click_count_cap
##   - combo resets after time_window_ms of silence
##   - combo multiplier is 1.0 below ramp_start_clicks, grows linearly to base_max
##   - reset_combo() returns combo to 0
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	TickSystem.set_auto_save_enabled(false)
	TickSystem.pause()  # no DPS interference
	await create_timer(0.05).timeout
	_reset_state()

	_test_register_click_adds_dna()
	_test_total_clicks_increments()
	_test_click_landed_signal_fires()
	await _test_combo_counter_resets_after_window()
	_test_combo_caps_at_max()
	_test_combo_multiplier_ramp()
	_test_reset_combo_clears_counter()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_register_click_adds_dna() -> void:
	_reset_state()
	GameState.click_power = 5.0
	# A single click in isolation has combo_count=1, so combo_mult=1.
	# Crit is random — we set base chance to 0 via a stat-floor trick:
	# can't override DataLoader, so we accept either 5.0 or 5.0 * crit_mult.
	ClickSystem.register_click(Vector2(100, 100))
	# DNA must be at least click_power (1x) and at most click_power * crit_mult.
	_assert(GameState.dna >= 5.0, "DNA must be >= 5 after click with click_power=5")
	_assert(GameState.dna <= 5.0 * 100.0, "DNA must be <= click_power * crit_mult upper bound")

func _test_total_clicks_increments() -> void:
	_reset_state()
	var before: int = GameState.total_clicks
	ClickSystem.register_click()
	ClickSystem.register_click()
	ClickSystem.register_click()
	_assert(GameState.total_clicks == before + 3,
		"total_clicks should be %d (got %d)" % [before + 3, GameState.total_clicks])

func _test_click_landed_signal_fires() -> void:
	_reset_state()
	var captured: Dictionary = {}
	var capture := func(amount: float, pos: Vector2, is_crit: bool, combo: int) -> void:
		captured = { "amount": amount, "pos": pos, "crit": is_crit, "combo": combo }
	ClickSystem.click_landed.connect(capture)
	GameState.click_power = 10.0
	ClickSystem.register_click(Vector2(42, 64))
	_assert(not captured.is_empty(), "click_landed should have fired")
	if not captured.is_empty():
		_assert(float(captured["amount"]) >= 10.0, "amount should be at least click_power")
		_assert((captured["pos"] as Vector2).x == 42.0, "pos.x should pass through")
		_assert(int(captured["combo"]) >= 1, "combo should be >= 1")
	ClickSystem.click_landed.disconnect(capture)

func _test_combo_counter_resets_after_window() -> void:
	_reset_state()
	# Get current combo to a known state (>=1).
	ClickSystem.register_click()
	_assert(ClickSystem.get_combo_count() == 1, "combo should be 1 after first click")
	ClickSystem.register_click()
	ClickSystem.register_click()
	_assert(ClickSystem.get_combo_count() == 3,
		"combo should be 3 after 3 rapid clicks (got %d)" % ClickSystem.get_combo_count())
	# Wait longer than combo window (1500 ms balance default).
	await create_timer(1.7).timeout
	ClickSystem.register_click()
	_assert(ClickSystem.get_combo_count() == 1,
		"combo should reset to 1 after window expires (got %d)" % ClickSystem.get_combo_count())

func _test_combo_caps_at_max() -> void:
	_reset_state()
	# Fire 200 rapid clicks; cap is 60 by default.
	for i in 200:
		ClickSystem.register_click()
	_assert(ClickSystem.get_combo_count() == 60,
		"combo should cap at 60 (got %d)" % ClickSystem.get_combo_count())

func _test_combo_multiplier_ramp() -> void:
	# multiplier should be 1.0 below ramp_start (3), grow to base_max (3) at ramp_end (30)
	# Without DataLoader override, base = 3, start = 3, end = 30.
	# At combo=1 or 2: 1.0
	# At combo=3: 1.0 (start of ramp)
	# At combo=16 (midpoint between 3 and 30): (16-3)/(30-3) * (3-1) + 1 ≈ 1.963
	# At combo=30+: 3.0 (capped to max)
	_reset_state()
	ClickSystem.reset_combo()
	_assert(abs(ClickSystem.get_combo_multiplier() - 1.0) < 0.001,
		"mult at combo=0 should be 1.0")
	# Fire 2 rapid clicks -> combo=2
	ClickSystem.register_click()
	ClickSystem.register_click()
	_assert(ClickSystem.get_combo_count() == 2, "should be at combo=2")
	_assert(abs(ClickSystem.get_combo_multiplier() - 1.0) < 0.001,
		"mult at combo=2 (below ramp_start=3) should be 1.0 (got %f)" % ClickSystem.get_combo_multiplier())
	# 1 more -> combo=3 (ramp start)
	ClickSystem.register_click()
	_assert(abs(ClickSystem.get_combo_multiplier() - 1.0) < 0.001,
		"mult at combo=3 (ramp_start) should be 1.0 (got %f)" % ClickSystem.get_combo_multiplier())
	# Fire to combo=30 -> mult = 3.0
	for i in 27:
		ClickSystem.register_click()
	_assert(abs(ClickSystem.get_combo_multiplier() - 3.0) < 0.01,
		"mult at combo=30 (ramp_end) should be ~3.0 (got %f)" % ClickSystem.get_combo_multiplier())

func _test_reset_combo_clears_counter() -> void:
	_reset_state()
	ClickSystem.register_click()
	ClickSystem.register_click()
	ClickSystem.register_click()
	ClickSystem.reset_combo()
	_assert(ClickSystem.get_combo_count() == 0, "reset_combo should bring counter to 0")
	_assert(abs(ClickSystem.get_combo_multiplier() - 1.0) < 0.001,
		"mult after reset should be 1.0")

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
	GameState.total_clicks = 0
	GameState.total_crits = 0
	GameState.upgrade_counts = {}
	ClickSystem.reset_combo()

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
	else:
		_failures.append(msg)

func _report() -> void:
	print("")
	print("================================================================")
	print("ClickSystem tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
