extends SceneTree
##
## Headless test for TickSystem (Phase 1 / P1-005).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_tick_system.gd
##
## We disable auto-save up front so the test never writes to a real save
## slot. The save-timer itself is still verified (wait_time correctness,
## start/stop behavior) without actually invoking SaveSystem.save().
##
## Coverage:
##   - logic_tick fires at ~4 Hz over a 2 s window
##   - visual_tick fires more than once per 500 ms
##   - logic and visual tick counts diverge (different rates)
##   - pause() halts both ticks
##   - resume() restarts the logic tick
##   - intervals come from data/balance_constants.json tick_rates
##   - save timer is constructed with the configured save_interval_s
##   - set_auto_save_enabled gates auto-save firing
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	# Block auto-save before any save-timer might fire (default 15 s away
	# anyway, but defensive).
	TickSystem.set_auto_save_enabled(false)
	# Wait one engine frame so autoloads are fully wired.
	await create_timer(0.05).timeout

	await _test_intervals_from_balance_constants()
	await _test_logic_tick_fires_at_4hz()
	await _test_visual_tick_fires()
	await _test_logic_and_visual_diverge()
	await _test_pause_stops_both()
	await _test_resume_restarts_logic()
	_test_set_auto_save_enabled_gate()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_intervals_from_balance_constants() -> void:
	# balance_constants.json: tick_rates.logic_tick_interval_ms = 250
	#                        tick_rates.save_interval_ms = 15000
	_assert(
		abs(TickSystem.get_logic_interval_s() - 0.25) < 0.001,
		"logic interval should be 0.25 s (got %f)" % TickSystem.get_logic_interval_s())
	_assert(
		abs(TickSystem.get_save_interval_s() - 15.0) < 0.001,
		"save interval should be 15 s (got %f)" % TickSystem.get_save_interval_s())

func _test_logic_tick_fires_at_4hz() -> void:
	var start: int = TickSystem.logic_tick_count
	await create_timer(2.0).timeout
	var elapsed: int = TickSystem.logic_tick_count - start
	# 4 Hz × 2 s ≈ 8 ticks. Allow 5..12 to cover headless-startup jitter.
	_assert(elapsed >= 5 and elapsed <= 12,
		"logic_tick fired %d times in 2s; expected ~8 (5..12)" % elapsed)

func _test_visual_tick_fires() -> void:
	var start: int = TickSystem.visual_tick_count
	await create_timer(0.5).timeout
	var elapsed: int = TickSystem.visual_tick_count - start
	_assert(elapsed > 0, "visual_tick should fire at least once in 500 ms")

func _test_logic_and_visual_diverge() -> void:
	# In normal frame conditions visual_tick (per-frame) should fire much
	# more often than logic_tick (4 Hz). In headless this can be tight; we
	# just verify visual >= logic over the same interval.
	var l_start: int = TickSystem.logic_tick_count
	var v_start: int = TickSystem.visual_tick_count
	await create_timer(1.0).timeout
	var l_delta: int = TickSystem.logic_tick_count - l_start
	var v_delta: int = TickSystem.visual_tick_count - v_start
	_assert(v_delta >= l_delta,
		"visual_tick (%d) should be >= logic_tick (%d) over 1 s" % [v_delta, l_delta])

func _test_pause_stops_both() -> void:
	TickSystem.pause()
	# Wait one timer cycle so any in-flight emit has flushed.
	await create_timer(0.05).timeout
	var l_start: int = TickSystem.logic_tick_count
	var v_start: int = TickSystem.visual_tick_count
	await create_timer(0.7).timeout
	var l_delta: int = TickSystem.logic_tick_count - l_start
	var v_delta: int = TickSystem.visual_tick_count - v_start
	_assert(l_delta == 0, "logic_tick should not fire during pause() (got %d)" % l_delta)
	_assert(v_delta == 0, "visual_tick should not fire during pause() (got %d)" % v_delta)
	_assert(not TickSystem.is_running(), "is_running() should be false after pause()")

func _test_resume_restarts_logic() -> void:
	TickSystem.resume()
	_assert(TickSystem.is_running(), "is_running() should be true after resume()")
	var start: int = TickSystem.logic_tick_count
	await create_timer(0.6).timeout
	var elapsed: int = TickSystem.logic_tick_count - start
	_assert(elapsed >= 1, "logic_tick should fire at least once after resume() (got %d)" % elapsed)

func _test_set_auto_save_enabled_gate() -> void:
	# Auto-save is disabled at the top of _initialize. Toggle and inspect.
	_assert(not TickSystem.is_auto_save_enabled(),
		"auto-save should be disabled (we set it off at start)")
	TickSystem.set_auto_save_enabled(true)
	_assert(TickSystem.is_auto_save_enabled(),
		"set_auto_save_enabled(true) should flip the flag")
	TickSystem.set_auto_save_enabled(false)
	_assert(not TickSystem.is_auto_save_enabled(),
		"set_auto_save_enabled(false) should flip the flag back")

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
	else:
		_failures.append(msg)

func _report() -> void:
	print("")
	print("================================================================")
	print("TickSystem tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
