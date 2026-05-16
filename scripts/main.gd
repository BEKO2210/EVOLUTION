extends Node
##
## Main bootstrap entry point.
##
## Phase 1 — P1-001 — Godot project setup.
##
## Currently a no-op: the project must load and run without errors so the
## Phase-1 acceptance test (clone → open → F5 → empty window, no errors)
## passes. Real systems land in subsequent tickets:
##   P1-002 — Autoload singletons (GameState, SaveSystem, DataLoader, AudioManager, SteamAPI, Telemetry)
##   P1-003 — DataLoader populates from data/*.json
##   P1-004 — SaveSystem with schema-version + migrations
##   P1-005 — TickSystem (logic 4 Hz, visual 60 Hz)
##   P1-006 — ClickSystem + UpgradeSystem
##   P1-007 — StageSystem
##   P1-008 — PrestigeSystem
##   P1-009 — AchievementSystem
##   P1-010 — BioNexus shader port (GLSL -> GDShader)
##   P1-011 — Greybox UI (tabs, panels, upgrade cards)
##   P1-012 — GodotSteam spike
##   P1-013 — Playtest sessions

func _ready() -> void:
	print("[Evolution] Phase 1 skeleton booted — engine %s" % Engine.get_version_info().string)
