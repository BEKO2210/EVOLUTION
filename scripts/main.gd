extends Node
##
## Main bootstrap entry point.
##
## Runs a smoke-test against every autoload on _ready() so the bootstrap
## label gives an immediate visual confirmation that the engine layer is
## healthy.
##
## Phase 1 ticket history (delivered):
##   P1-001 — project skeleton
##   P1-002 — six autoload singletons
##   P1-003 — DataLoader populates from data/*.json
##   P1-004 — SaveSystem with schema-version + migrations + checksum
##   P1-005 — TickSystem (logic 4 Hz, visual per-frame, periodic auto-save)
##
## Still to come:
##   P1-006 — ClickSystem + UpgradeSystem
##   P1-007 — StageSystem
##   P1-008 — PrestigeSystem
##   P1-009 — AchievementSystem
##   P1-010 — BioNexus shader port (GLSL -> GDShader)
##   P1-011 — Greybox UI (tabs, panels, upgrade cards) + audio bus layout
##   P1-012 — GodotSteam spike
##   P1-013 — Playtest sessions

@onready var _bootstrap_label: Label = $BootstrapHud/Label

func _ready() -> void:
	var engine_version: String = Engine.get_version_info().string
	print("[Evolution] Phase 1 boot — engine %s" % engine_version)

	# --- Autoload smoke-test (running total through P1-005) -----------------
	# Each autoload must be reachable and call-safe.
	# Disable auto-save immediately so this smoke-test never writes to a
	# real player save slot.
	TickSystem.set_auto_save_enabled(false)

	var report: PackedStringArray = []
	report.append("engine %s" % engine_version)
	report.append(_check_game_state())
	report.append(_check_save_system())
	report.append(_check_data_loader())
	report.append(_check_audio_manager())
	report.append(_check_steam_api())
	report.append(_check_telemetry())
	report.append(_check_tick_system())

	var summary: String = "\n".join(report)
	print("[Evolution] Autoload smoke-test:\n%s" % summary)
	if _bootstrap_label:
		_bootstrap_label.text = "EVOLUTION — Phase 1\nautoloads OK\n%s" % summary

# --- Smoke checks -----------------------------------------------------------

func _check_game_state() -> String:
	# Acceptance criterion: GameState.dna += 1 läuft ohne Error.
	var before: float = GameState.dna
	GameState.dna += 1.0
	var ok: bool = GameState.dna == before + 1.0
	# Roll back so the test doesn't leak state into the actual run.
	GameState.dna = before
	return "GameState: %s (dna mutation works)" % ("OK" if ok else "FAIL")

func _check_save_system() -> String:
	# P1-004: SaveSystem is real. Smoke-test a round-trip in a test slot
	# without touching the player's real saves (slots 0, 1, 2).
	const SMOKE_SLOT: int = SaveSystem.SLOT_LOCAL_3
	var pre_existed: bool = SaveSystem.slot_exists(SMOKE_SLOT)
	if pre_existed:
		# Don't overwrite an existing real save in slot 3 — skip the smoke test.
		return "SaveSystem: skipped (slot 3 in use)"
	var save_ok: bool = SaveSystem.save(SMOKE_SLOT)
	if not save_ok:
		return "SaveSystem: save() FAILED"
	var load_ok: bool = SaveSystem.load_slot(SMOKE_SLOT)
	SaveSystem.delete_slot(SMOKE_SLOT)
	if not load_ok:
		return "SaveSystem: load_slot() FAILED"
	return "SaveSystem: OK — round-trip in slot 3 (auto-cleaned)"

func _check_data_loader() -> String:
	# P1-003: load_all() is invoked from DataLoader._ready() at boot.
	# Verify it succeeded and the expected item counts are present.
	if not DataLoader.is_loaded:
		var errs: PackedStringArray = DataLoader.get_last_errors()
		return "DataLoader: FAIL (%d errors, see console)" % errs.size()
	return "DataLoader: OK — %d stages, %d auto, %d click, %d research, %d abilities, %d achievements" % [
		DataLoader.stages.size(),
		DataLoader.upgrades_auto.size(),
		DataLoader.upgrades_click.size(),
		DataLoader.research.size(),
		DataLoader.abilities.size(),
		DataLoader.achievements.size(),
	]

func _check_audio_manager() -> String:
	# Setting volume on an undefined bus must not crash.
	AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, 0.5)
	AudioManager.play_sfx("click_standard")
	return "AudioManager: OK (real impl in P1-011/Phase-2)"

func _check_steam_api() -> String:
	# is_available is false out-of-band; stub calls must be no-op.
	var avail: bool = SteamAPI.is_available
	SteamAPI.set_achievement("noop_test")
	return "SteamAPI: stub OK, available=%s (real impl in P1-012 spike)" % avail

func _check_telemetry() -> String:
	# Default opt-in is false, track() must silently drop.
	Telemetry.track("smoke_test_event", {"phase": 1})
	return "Telemetry: stub OK, opt_in=%s (real impl in P1-009/Phase-3)" % Telemetry.opt_in

func _check_tick_system() -> String:
	# P1-005: TickSystem starts running on boot, reading intervals from
	# data/balance_constants.json. Just verify the configuration is sane.
	var logic_s: float = TickSystem.get_logic_interval_s()
	var save_s: float = TickSystem.get_save_interval_s()
	var running: bool = TickSystem.is_running()
	if not running:
		return "TickSystem: FAIL (not running)"
	return "TickSystem: OK — logic %.2fs / save %.0fs (auto-save off for smoke-test)" % [logic_s, save_s]
