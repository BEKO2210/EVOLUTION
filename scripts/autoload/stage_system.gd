extends Node
##
## StageSystem — owns the player's current evolution stage.
##
## Phase 1 / P1-007.
##
## Drives:
##   GameState.stage  (writes when a higher threshold is crossed)
##   GameState.stage_changed signal  (emits with new_stage, old_stage)
##
## Inputs:
##   data/stages.json (loaded by DataLoader) — threshold_dna per tier
##   GameState.total_dna_changed signal — fires only when run total grows
##   GameState.state_reset signal — fires from prestige; recompute stage
##
## Design:
## - Threshold is checked against GameState.total_dna (run total, monotonic
##   per run) — NOT against `dna` (which goes down on spend) and NOT against
##   `lifetime_dna` (which would survive prestige and prevent stage reset).
## - Multiple thresholds crossed by a single add_dna() emit ONE
##   stage_changed signal with the highest reached tier. Subscribers (UI,
##   achievement system, SFX) handle the jump in one event — no flicker.
## - Stage cannot drop below the threshold-derived value. The only way to
##   go down is via state_reset (prestige) which clears total_dna to 0.

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	GameState.total_dna_changed.connect(_on_total_dna_changed)
	GameState.state_reset.connect(_on_state_reset)
	# Initial recompute so a freshly-loaded save lands on the right tier.
	# DataLoader is autoloaded before StageSystem (see project.godot), so
	# stages are available here.
	recompute_stage()

# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

## Pure function: returns the tier the player would be at given a total_dna.
## Used by UI/codex preview and exposed for tests.
func get_stage_for_total_dna(total_dna: float) -> int:
	if not DataLoader.is_loaded or DataLoader.stages.is_empty():
		return 1
	# Stages are ordered by tier and thresholds are monotonic; once we hit a
	# threshold that's too high we can break early.
	var reached: int = 1
	for stage_data in DataLoader.stages:
		var threshold: float = float(stage_data["threshold_dna"])
		if total_dna >= threshold:
			reached = int(stage_data["tier"])
		else:
			break
	return reached

## Force-recompute GameState.stage from the current total_dna and emit
## stage_changed if it actually moved. Safe to call any time; idempotent.
func recompute_stage() -> void:
	var target: int = get_stage_for_total_dna(GameState.total_dna)
	if target != GameState.stage:
		var old: int = GameState.stage
		GameState.stage = target
		GameState.stage_changed.emit(target, old)

## True if a threshold_dna for the given tier exists in the loaded stages.
func has_stage(tier: int) -> bool:
	return DataLoader.get_stage_by_tier(tier) != null

## Threshold required to reach a given tier (0 for tier 1).
func get_threshold_for_tier(tier: int) -> float:
	var s: Variant = DataLoader.get_stage_by_tier(tier)
	if s == null:
		return INF
	return float(s["threshold_dna"])

# ----------------------------------------------------------------------------
# INTERNAL
# ----------------------------------------------------------------------------

func _on_total_dna_changed(new_total_dna: float, _delta: float) -> void:
	# Only ever moves stage upward; total_dna is monotonic within a run.
	var target: int = get_stage_for_total_dna(new_total_dna)
	if target > GameState.stage:
		var old: int = GameState.stage
		GameState.stage = target
		GameState.stage_changed.emit(target, old)

func _on_state_reset() -> void:
	# Prestige reset wipes total_dna; recompute (will normally land on 1).
	# GameState.reset_for_prestige() already sets stage=1, but emitting a
	# stage_changed signal here is the cleanest way to tell the UI/FX to
	# rewind. Use the helper, which is a no-op if stage is already correct.
	recompute_stage()
