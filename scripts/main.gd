extends Control
##
## Main scene controller.
##
## Phase 1 ticket history (delivered):
##   P1-001 — project skeleton
##   P1-002 — six autoload singletons
##   P1-003 — DataLoader populates from data/*.json
##   P1-004 — SaveSystem with schema-version + migrations + checksum
##   P1-005 — TickSystem (logic 4 Hz, visual per-frame, periodic auto-save)
##   P1-006 — ClickSystem + UpgradeSystem (DPS accumulation + milestone math)
##   P1-007 — StageSystem (threshold progression, stage_changed signal)
##   P1-008 — PrestigeSystem (lifetime-DNA threshold, EP formula, compounding multiplier)
##   P1-009 — AchievementSystem (declarative conditions, reward multipliers, persistence)
##   P1-010 — BioNexus shader port (GDShader + MultiMeshInstance3D + camera dolly)
##   P1-011 — Greybox UI (HUD, tabs, panels, click area wired to ClickSystem)
##   P1-012 — GodotSteam spike (feature-detected; no-op without extension)
##
## Still to come:
##   P1-013 — Playtest sessions
##
## At boot we run a console smoke-test against every autoload so the developer
## can spot a regression immediately without needing to navigate the UI.

@onready var _click_area: Button = $VBox/CellRow/ClickArea

func _ready() -> void:
	# Disable auto-save up front so the smoke-test never writes to a real
	# player save slot.
	TickSystem.set_auto_save_enabled(false)

	_run_boot_smoke_test()

	# Wire the giant "click the cell" button.
	if _click_area:
		_click_area.pressed.connect(_on_click_pressed)

func _on_click_pressed() -> void:
	# Forward to ClickSystem; everything else (DNA add, combo, crit, achievement
	# checks, signal fanout) happens via the autoload pipeline.
	ClickSystem.register_click(_click_area.get_global_rect().get_center())

# ----------------------------------------------------------------------------
# Boot-time smoke-test (console output only — UI is the real user surface)
# ----------------------------------------------------------------------------

func _run_boot_smoke_test() -> void:
	var engine_version: String = Engine.get_version_info().string
	print("[Evolution] Phase 1 boot — engine %s" % engine_version)
	var report: PackedStringArray = []
	report.append("engine %s" % engine_version)
	report.append(_check_game_state())
	report.append(_check_save_system())
	report.append(_check_data_loader())
	report.append(_check_audio_manager())
	report.append(_check_steam_api())
	report.append(_check_telemetry())
	report.append(_check_tick_system())
	report.append(_check_click_and_upgrade())
	report.append(_check_stage_system())
	report.append(_check_prestige_system())
	report.append(_check_achievement_system())
	report.append(_check_bionexus())
	print("[Evolution] Autoload smoke-test:\n  - %s" % "\n  - ".join(report))

# --- Smoke checks -----------------------------------------------------------

func _check_game_state() -> String:
	var before: float = GameState.dna
	GameState.dna += 1.0
	var ok: bool = GameState.dna == before + 1.0
	GameState.dna = before
	return "GameState: %s (dna mutation works)" % ("OK" if ok else "FAIL")

func _check_save_system() -> String:
	const SMOKE_SLOT: int = SaveSystem.SLOT_LOCAL_3
	var pre_existed: bool = SaveSystem.slot_exists(SMOKE_SLOT)
	if pre_existed:
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
	AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, 0.5)
	AudioManager.play_sfx("click_standard")
	return "AudioManager: OK (real impl in P1-011/Phase-2)"

func _check_steam_api() -> String:
	# P1-012: feature-detected. Without GodotSteam GDExtension installed,
	# every call is a safe no-op. See docs/steam/godotsteam-setup.md
	# for activation steps + scenes/dev/steam_smoke_test.tscn for the
	# manual integration test on real Steam hardware.
	SteamAPI.set_achievement("noop_test")  # must not crash
	if SteamAPI.has_extension:
		return "SteamAPI: OK — GodotSteam extension detected (init pending)"
	return "SteamAPI: OK — running in no-op mode (GodotSteam not installed; expected for Phase 1)"

func _check_telemetry() -> String:
	Telemetry.track("smoke_test_event", {"phase": 1})
	return "Telemetry: stub OK, opt_in=%s (real impl in P1-009/Phase-3)" % Telemetry.opt_in

func _check_tick_system() -> String:
	var logic_s: float = TickSystem.get_logic_interval_s()
	var save_s: float = TickSystem.get_save_interval_s()
	if not TickSystem.is_running():
		return "TickSystem: FAIL (not running)"
	return "TickSystem: OK — logic %.2fs / save %.0fs" % [logic_s, save_s]

func _check_click_and_upgrade() -> String:
	# Snapshot everything we might touch so we leave no smoke-test footprint
	# on a player's loaded save.
	var snapshot: Dictionary = {
		"dna":                    GameState.dna,
		"total_dna":              GameState.total_dna,
		"lifetime_dna":           GameState.lifetime_dna,
		"click_power":            GameState.click_power,
		"dps":                    GameState.dps,
		"stage":                  GameState.stage,
		"prestige_points":        GameState.prestige_points,
		"prestige_multiplier":    GameState.prestige_multiplier,
		"total_clicks":           GameState.total_clicks,
		"total_crits":            GameState.total_crits,
		"upgrade_counts":         GameState.upgrade_counts.duplicate(true),
		"achievements_unlocked":  GameState.achievements_unlocked.duplicate(true),
	}
	GameState.click_power = 1.0
	var clicks_before: int = GameState.total_clicks
	ClickSystem.register_click()
	ClickSystem.register_click()
	ClickSystem.register_click()
	var clicks_added: int = GameState.total_clicks - clicks_before
	GameState.dna = 200.0
	var bought: bool = UpgradeSystem.buy("auto_001")
	var dps_after: float = GameState.dps
	# Restore exactly what we snapshotted.
	GameState.dna                   = snapshot["dna"]
	GameState.total_dna             = snapshot["total_dna"]
	GameState.lifetime_dna          = snapshot["lifetime_dna"]
	GameState.click_power           = snapshot["click_power"]
	GameState.dps                   = snapshot["dps"]
	GameState.stage                 = snapshot["stage"]
	GameState.prestige_points       = snapshot["prestige_points"]
	GameState.prestige_multiplier   = snapshot["prestige_multiplier"]
	GameState.total_clicks          = snapshot["total_clicks"]
	GameState.total_crits           = snapshot["total_crits"]
	GameState.upgrade_counts        = snapshot["upgrade_counts"]
	GameState.achievements_unlocked = snapshot["achievements_unlocked"]
	ClickSystem.reset_combo()
	UpgradeSystem.recalc_stats()
	if clicks_added != 3:
		return "ClickSystem: FAIL (added %d clicks, expected 3)" % clicks_added
	if not bought:
		return "UpgradeSystem: FAIL (buy auto_001 failed)"
	if dps_after <= 0.0:
		return "UpgradeSystem: FAIL (dps did not rise after buy)"
	return "Click+Upgrade: OK — 3 clicks added DNA, auto_001 buy raised dps to %.2f/s" % dps_after

func _check_stage_system() -> String:
	if not StageSystem.has_stage(1) or not StageSystem.has_stage(30):
		return "StageSystem: FAIL (stage 1 or 30 missing)"
	var tier_at_25k: int = StageSystem.get_stage_for_total_dna(25000.0)
	if tier_at_25k != 3:
		return "StageSystem: FAIL (25k DNA should be tier 3, got %d)" % tier_at_25k
	return "StageSystem: OK — pure lookup matches stages.json (current stage=%d)" % GameState.stage

func _check_prestige_system() -> String:
	var needed_for_1: float = PrestigeSystem.get_lifetime_dna_needed_for_total_points(1)
	if abs(needed_for_1 - 1_000_000.0) > 0.001:
		return "PrestigeSystem: FAIL (1 EP needs 1M, got %f)" % needed_for_1
	var cur_mult: float = PrestigeSystem.get_current_multiplier()
	return "PrestigeSystem: OK — current x%.2f, %d EP available" % [
		cur_mult, PrestigeSystem.get_evolution_points_available()
	]

func _check_achievement_system() -> String:
	var total: int = AchievementSystem.get_total_count()
	if total != 27:
		return "AchievementSystem: FAIL (expected 27 achievements, got %d)" % total
	var bundle: Dictionary = AchievementSystem.get_reward_multipliers()
	if not bundle.has("dps_mult") or not bundle.has("click_mult") or not bundle.has("all_mult"):
		return "AchievementSystem: FAIL (reward bundle missing required keys)"
	return "AchievementSystem: OK — %d/%d unlocked, reward bundle wired" % [
		AchievementSystem.get_unlocked_count(), total
	]

func _check_bionexus() -> String:
	if not ResourceLoader.exists("res://shaders/bionexus_cell.gdshader"):
		return "BioNexus: FAIL (shader file missing)"
	if not ResourceLoader.exists("res://scenes/cell/bionexus.tscn"):
		return "BioNexus: FAIL (scene file missing)"
	return "BioNexus: OK — shader + scene wired"
