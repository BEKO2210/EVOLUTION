extends Node
##
## GameState — single source of truth for runtime game values.
##
## Phase 1 / P1-002. Mirrors the `game` object from the HTML prototype
## (index.html, `let game = { ... }`) in Godot-idiomatic snake_case form.
##
## Fields are public properties for direct read/write from systems
## (UpgradeSystem, ClickSystem, etc.). Signals fire on mutations that the UI
## must react to.
##
## Real recalc_stats / addDna / etc. land in P1-005..P1-009. This file
## currently only defines the shape and a couple of helper methods
## (add_dna, reset_for_prestige) so other autoloads can compile against a
## stable interface.
##
## Save/Load is delegated to SaveSystem (see ADR-0003).
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal dna_changed(new_dna: float, delta: float)
## Fires only when total_dna grows (never on spend). StageSystem subscribes
## to this rather than dna_changed so it doesn't re-evaluate thresholds on
## every spend (and so stage cannot drift downward).
signal total_dna_changed(new_total_dna: float, delta: float)
signal stage_changed(new_stage: int, old_stage: int)
signal upgrade_count_changed(upgrade_id: String, new_count: int)
signal achievement_unlocked(achievement_id: String)
signal prestige_performed(evolution_points_gained: int)
signal state_reset()

# ----------------------------------------------------------------------------
# RESOURCES (DNA economy)
# ----------------------------------------------------------------------------
var dna: float = 0.0                         ## current DNA (spendable)
var total_dna: float = 0.0                   ## lifetime DNA earned this run
var lifetime_dna: float = 0.0                ## lifetime DNA across all prestiges
var click_power: float = 1.0                 ## DNA per click (derived; recalc_stats writes)
var dps: float = 0.0                         ## DNA per second (derived; recalc_stats writes)

# ----------------------------------------------------------------------------
# PROGRESSION
# ----------------------------------------------------------------------------
var stage: int = 1                           ## current stage (1..30, see data/stages.json)
var divisions: int = 0                       ## permanent mitose divisions performed

# ----------------------------------------------------------------------------
# PRESTIGE
# ----------------------------------------------------------------------------
var prestige_points: int = 0                 ## cumulative evolutionspunkte
var prestige_multiplier: float = 1.0         ## derived = pow(1.10, prestige_points)

# ----------------------------------------------------------------------------
# AUTO CLICKER (Meta)
# ----------------------------------------------------------------------------
var auto_clicker_level: int = 0

# ----------------------------------------------------------------------------
# TIME TRACKING (UTC unix seconds, deterministic for offline progression)
# ----------------------------------------------------------------------------
var start_time_unix: int = 0                 ## when this save was first created
var last_tick_unix: int = 0                  ## last logic-tick wallclock for offline calc
var last_real_tick_unix: int = 0             ## last engine-tick

# ----------------------------------------------------------------------------
# COUNTERS (achievement triggers)
# ----------------------------------------------------------------------------
var total_clicks: int = 0
var total_crits: int = 0
var total_goldens: int = 0

# ----------------------------------------------------------------------------
# SETTINGS (will be moved to a dedicated Settings autoload if it grows)
# ----------------------------------------------------------------------------
var sound: bool = true
var haptic: bool = true
var buy_mode: Variant = 1                    ## 1 | 10 | 100 | "max"
var active_tab: String = "auto"

# ----------------------------------------------------------------------------
# NESTED COLLECTIONS — populated/mutated by systems
# ----------------------------------------------------------------------------
## upgrade_id -> int (count owned). Keys mirror data/upgrades_*.json `id`.
var upgrade_counts: Dictionary = {}
## research_id -> int (unix when researched; 0 = not researched)
var research_unlocked: Dictionary = {}
## achievement_id -> int (unix when unlocked; missing key = locked)
var achievements_unlocked: Dictionary = {}
## ability_id -> { "last_used_unix": int, "active_until_unix": int }
var abilities_state: Dictionary = {}

# ----------------------------------------------------------------------------
# MUTATIONS (random event state)
# ----------------------------------------------------------------------------
var active_mutation_id: String = ""
var mutation_ends_at_unix: int = 0

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	start_time_unix = now
	last_tick_unix = now
	last_real_tick_unix = now

# ----------------------------------------------------------------------------
# PUBLIC API — minimal helpers callable from systems
# ----------------------------------------------------------------------------

## Add DNA, update lifetime trackers, emit signals.
## Real systems use this so achievement triggers + dna_changed fire consistently.
## Emits both dna_changed (current spendable) and total_dna_changed (run total)
## so subscribers can pick the right one.
func add_dna(amount: float) -> void:
	if amount == 0.0:
		return
	dna += amount
	total_dna += amount
	lifetime_dna += amount
	dna_changed.emit(dna, amount)
	total_dna_changed.emit(total_dna, amount)

## Subtract DNA. Returns true if successful, false if insufficient funds.
func spend_dna(amount: float) -> bool:
	if dna < amount:
		return false
	dna -= amount
	dna_changed.emit(dna, -amount)
	return true

## Reset run-state on prestige but keep prestige_points + research + achievements.
## Phase-1 stub — real reset logic ships in PrestigeSystem (P1-008).
func reset_for_prestige() -> void:
	dna = 0.0
	total_dna = 0.0
	stage = 1
	auto_clicker_level = 0
	upgrade_counts.clear()
	divisions = 0
	state_reset.emit()
