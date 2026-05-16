extends Node
##
## DataLoader — loads all data/*.json into typed in-memory tables.
##
## Phase 1 / P1-002. Stub interface only — real load + validation in P1-003.
## Strategy in docs/decisions/ADR-0004-data-driven-upgrades.md.
## Schema spec in data/schema-notes.md.
##
## Reads:
##   data/stages.json
##   data/upgrades_auto.json
##   data/upgrades_click.json
##   data/research.json
##   data/abilities.json
##   data/achievements.json
##   data/balance_constants.json
##
## Provides O(1) lookups by ID + ordered arrays for UI rendering.
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal data_loaded()
signal data_validation_failed(file: String, reason: String)

# ----------------------------------------------------------------------------
# DATA TABLES (populated by load_all)
# ----------------------------------------------------------------------------
## Ordered arrays preserve tier sequence for UI.
var stages: Array = []
var upgrades_auto: Array = []
var upgrades_click: Array = []
var research: Array = []
var abilities: Array = []
var achievements: Array = []
var balance: Dictionary = {}

## ID -> Dictionary lookups for fast access.
var _stage_by_id: Dictionary = {}
var _upgrade_auto_by_id: Dictionary = {}
var _upgrade_click_by_id: Dictionary = {}
var _research_by_id: Dictionary = {}
var _ability_by_id: Dictionary = {}
var _achievement_by_id: Dictionary = {}

var is_loaded: bool = false

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Real load_all() invocation happens after autoload init order is settled,
	# in P1-003. For P1-002 we defer to keep this stub no-op-safe.
	pass

# ----------------------------------------------------------------------------
# PUBLIC API — stubs
# ----------------------------------------------------------------------------

## Load every data/*.json file, validate schemas, populate lookups.
## Stub: real impl + per-file validators land in P1-003.
func load_all() -> bool:
	push_warning("[DataLoader] load_all() is a stub; real impl in P1-003.")
	is_loaded = false
	return false

## Lookup helpers — stubs return null until P1-003.
func get_stage(stage_id: String) -> Variant:
	return _stage_by_id.get(stage_id, null)

func get_upgrade_auto(upgrade_id: String) -> Variant:
	return _upgrade_auto_by_id.get(upgrade_id, null)

func get_upgrade_click(upgrade_id: String) -> Variant:
	return _upgrade_click_by_id.get(upgrade_id, null)

func get_research(research_id: String) -> Variant:
	return _research_by_id.get(research_id, null)

func get_ability(ability_id: String) -> Variant:
	return _ability_by_id.get(ability_id, null)

func get_achievement(achievement_id: String) -> Variant:
	return _achievement_by_id.get(achievement_id, null)

## Helper for stage-by-tier lookups (faster than searching by ID).
func get_stage_by_tier(tier: int) -> Variant:
	if tier < 1 or tier > stages.size():
		return null
	return stages[tier - 1]
