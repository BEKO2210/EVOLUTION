extends SceneTree
##
## Headless test for SteamAPI (Phase 1 / P1-012 spike).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_steam_api.gd
##
## This suite runs WITHOUT GodotSteam installed. It verifies the no-op
## guards work correctly so the rest of the game can call SteamAPI methods
## freely whether or not Steam is present.
##
## When GodotSteam IS installed (Phase 2+), the manual smoke-test scene
## scenes/dev/steam_smoke_test.tscn validates the live integration.
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	TickSystem.set_auto_save_enabled(false)
	TickSystem.pause()
	await create_timer(0.05).timeout

	_test_extension_detection()
	_test_initial_state()
	_test_initialize_no_op_when_extension_absent()
	_test_set_achievement_no_op()
	_test_cloud_write_no_op()
	_test_cloud_read_returns_empty()
	_test_rich_presence_no_op()
	_test_constants_present()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_extension_detection() -> void:
	# In the headless test environment the GodotSteam GDExtension is NOT
	# installed (intentional — Phase 1 doesn't ship it). has_extension
	# must reflect that.
	if SteamAPI.has_extension:
		_failures.append("has_extension is true but GodotSteam shouldn't be installed in tests")
		return
	_passes += 1

func _test_initial_state() -> void:
	if SteamAPI.is_available:
		_failures.append("is_available should be false without GodotSteam loaded")
		return
	if SteamAPI.app_id != 0:
		_failures.append("app_id should default to 0 (got %d)" % SteamAPI.app_id)
		return
	if not SteamAPI.steam_user_name.is_empty():
		_failures.append("steam_user_name should default to empty string")
		return
	_passes += 1

func _test_initialize_no_op_when_extension_absent() -> void:
	# Capture the initialized signal to verify it fires false.
	var captured: Array = []
	var capture := func(success: bool, app_id_arg: int) -> void:
		captured.append({"success": success, "app_id": app_id_arg})
	SteamAPI.initialized.connect(capture)
	var result: bool = SteamAPI.initialize(SteamAPI.SPACEWAR_APP_ID)
	SteamAPI.initialized.disconnect(capture)
	if result:
		_failures.append("initialize() returned true without GodotSteam installed")
		return
	if SteamAPI.is_available:
		_failures.append("is_available true after failed init")
		return
	if captured.size() != 1:
		_failures.append("initialized signal didn't fire exactly once (got %d)" % captured.size())
		return
	if captured[0]["success"]:
		_failures.append("initialized signal reports success=true on a no-op init")
		return
	if int(captured[0]["app_id"]) != SteamAPI.SPACEWAR_APP_ID:
		_failures.append("initialized signal forwards wrong app_id")
		return
	_passes += 1

func _test_set_achievement_no_op() -> void:
	# Should return false and not crash.
	var ok: bool = SteamAPI.set_achievement("ACH_TEST_DOES_NOT_EXIST")
	if ok:
		_failures.append("set_achievement returned true on no-op call")
		return
	_passes += 1

func _test_cloud_write_no_op() -> void:
	var ok: bool = SteamAPI.cloud_save_text("test.txt", "some content")
	if ok:
		_failures.append("cloud_save_text returned true on no-op call")
		return
	_passes += 1

func _test_cloud_read_returns_empty() -> void:
	var content: String = SteamAPI.cloud_load_text("test.txt")
	if not content.is_empty():
		_failures.append("cloud_load_text returned non-empty on no-op call (got '%s')" % content)
		return
	_passes += 1

func _test_rich_presence_no_op() -> void:
	# Just verify it doesn't crash.
	SteamAPI.set_rich_presence("status", "test")
	_passes += 1

func _test_constants_present() -> void:
	# Spike acceptance includes "AppID 480 for Spacewar".
	if SteamAPI.SPACEWAR_APP_ID != 480:
		_failures.append("SPACEWAR_APP_ID constant should be 480 (got %d)" % SteamAPI.SPACEWAR_APP_ID)
		return
	if SteamAPI.STEAM_SINGLETON_NAME != "Steam":
		_failures.append("STEAM_SINGLETON_NAME should be 'Steam'")
		return
	_passes += 1

# ----------------------------------------------------------------------------
# Reporting
# ----------------------------------------------------------------------------

func _report() -> void:
	print("")
	print("================================================================")
	print("SteamAPI tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed (running without GodotSteam — no-op mode)")
	print("")
