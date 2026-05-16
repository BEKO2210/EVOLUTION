extends Node
##
## Main bootstrap entry point.
##
## Phase 1 — P1-001 brought the project skeleton, P1-002 registers the
## six autoload singletons. This script now runs a smoke-test against each
## autoload on _ready() to satisfy the P1-002 acceptance criterion:
##
##   "Autoloads sind im Editor sichtbar. GameState.dna += 1 läuft ohne Error."
##
## Real systems land in subsequent tickets:
##   P1-003 — DataLoader populates from data/*.json
##   P1-004 — SaveSystem with schema-version + migrations
##   P1-005 — TickSystem (logic 4 Hz, visual 60 Hz)
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

	# --- P1-002 acceptance smoke-test ---------------------------------------
	# Each autoload must be reachable and call-safe.
	var report: PackedStringArray = []
	report.append("engine %s" % engine_version)
	report.append(_check_game_state())
	report.append(_check_save_system())
	report.append(_check_data_loader())
	report.append(_check_audio_manager())
	report.append(_check_steam_api())
	report.append(_check_telemetry())

	var summary: String = "\n".join(report)
	print("[Evolution] Autoload smoke-test:\n%s" % summary)
	if _bootstrap_label:
		_bootstrap_label.text = "EVOLUTION — Phase 1\nP1-002 autoloads OK\n%s" % summary

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
	# Stub returns false — that's correct for P1-002.
	var stub_result: bool = SaveSystem.save(SaveSystem.SLOT_CLOUD)
	return "SaveSystem: stub %s (real impl in P1-004)" % ("OK" if not stub_result else "UNEXPECTED")

func _check_data_loader() -> String:
	# Lookups against unloaded tables must return null without crashing.
	var miss: Variant = DataLoader.get_stage("stage_001")
	return "DataLoader: lookup-safe %s (real impl in P1-003)" % ("OK" if miss == null else "UNEXPECTED")

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
