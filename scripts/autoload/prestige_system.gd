extends Node
##
## PrestigeSystem — soft-reset for the meta progression layer.
##
## Phase 1 / P1-008.
##
## Mechanic (from data/balance_constants.json prestige.*):
##   - Eligible to prestige once lifetime_dna >= lifetime_dna_threshold (1M).
##   - Evolutionspunkte (EP) earned per prestige:
##       earned = floor(sqrt(lifetime_dna / 1M)) - prestige_points
##     i.e. classic idle "ascend" curve — each successive prestige requires
##     quadratically more lifetime DNA.
##   - prestige_multiplier = base_multiplier_per_point ^ prestige_points
##     i.e. compounding 1.10× per point. Applied to dps + click_power by
##     UpgradeSystem.recalc_stats().
##
## What this autoload does:
##   - exposes can_prestige(), get_evolution_points_available(),
##     get_current_multiplier(), get_next_multiplier_after_prestige()
##   - do_prestige() runs the actual reset; UI is responsible for the
##     confirm dialog before invoking
##   - emits GameState.prestige_performed(gained) when a prestige succeeds
##
## What this autoload deliberately does NOT do:
##   - no confirm dialog (UI concern, P1-011)
##   - no auto-trigger (player intent always required)
##   - no skill-tree allocation (Phase 3)
##

# ----------------------------------------------------------------------------
# DEFAULTS — used until DataLoader.balance is populated.
# ----------------------------------------------------------------------------
const DEFAULT_LIFETIME_THRESHOLD: float = 1_000_000.0
const DEFAULT_BASE_MULT_PER_POINT: float = 1.10

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Ensure GameState.prestige_multiplier reflects any saved prestige_points
	# (a freshly loaded save may have points but a stale multiplier from an
	# older schema). Idempotent; recalc_multiplier writes only when needed.
	recalc_multiplier()

# ----------------------------------------------------------------------------
# PUBLIC API — queries
# ----------------------------------------------------------------------------

## True if the player has enough lifetime DNA to claim >= 1 evolution point.
func can_prestige() -> bool:
	return get_evolution_points_available() >= 1

## EP available to claim right now (already-claimed points are subtracted).
## Always >= 0.
func get_evolution_points_available() -> int:
	var threshold: float = _get_lifetime_threshold()
	if GameState.lifetime_dna < threshold:
		return 0
	var total_earned: int = int(floor(sqrt(GameState.lifetime_dna / threshold)))
	return max(0, total_earned - GameState.prestige_points)

## Current applied multiplier (= 1.10^prestige_points).
## Mirrors GameState.prestige_multiplier; provided for symmetry with the
## next_multiplier helper below.
func get_current_multiplier() -> float:
	return _multiplier_for(GameState.prestige_points)

## What the multiplier WOULD become if the player prestiged right now.
## Useful for UI ("Prestige now → ×1.46 PPS").
func get_next_multiplier_after_prestige() -> float:
	var gained: int = get_evolution_points_available()
	return _multiplier_for(GameState.prestige_points + gained)

## Lifetime DNA needed to reach a given total-EP count (inverse of the EP
## formula). Use for UI progress bars.
##   total_ep = floor(sqrt(lifetime_dna / threshold))
##   lifetime_dna >= total_ep^2 * threshold
func get_lifetime_dna_needed_for_total_points(total_points: int) -> float:
	if total_points <= 0:
		return 0.0
	return float(total_points * total_points) * _get_lifetime_threshold()

# ----------------------------------------------------------------------------
# PUBLIC API — mutations
# ----------------------------------------------------------------------------

## Perform the prestige reset. UI must confirm with the player BEFORE calling.
## Returns the number of EP gained (0 on failure).
##
## Side-effects:
##   1. GameState.prestige_points += gained
##   2. GameState.prestige_multiplier = base^new_total_points
##   3. GameState.reset_for_prestige() — wipes dna, total_dna, stage,
##      upgrade_counts, divisions. lifetime_dna is preserved.
##      Emits state_reset() → UpgradeSystem.recalc_stats() picks up the
##      new multiplier.
##   4. GameState.prestige_performed(gained) is emitted.
func do_prestige() -> int:
	var gained: int = get_evolution_points_available()
	if gained <= 0:
		return 0
	GameState.prestige_points += gained
	GameState.prestige_multiplier = _multiplier_for(GameState.prestige_points)
	GameState.reset_for_prestige()  # emits state_reset
	GameState.prestige_performed.emit(gained)
	return gained

## Force-recompute GameState.prestige_multiplier from prestige_points.
## Idempotent. Called on _ready() so a freshly loaded save with stale or
## missing multiplier converges to the canonical value.
func recalc_multiplier() -> void:
	GameState.prestige_multiplier = _multiplier_for(GameState.prestige_points)

# ----------------------------------------------------------------------------
# INTERNAL
# ----------------------------------------------------------------------------

func _multiplier_for(points: int) -> float:
	return pow(_get_base_mult_per_point(), float(max(0, points)))

func _get_lifetime_threshold() -> float:
	if not DataLoader.is_loaded:
		return DEFAULT_LIFETIME_THRESHOLD
	var p: Dictionary = DataLoader.balance.get("prestige", {}) as Dictionary
	return float(p.get("lifetime_dna_threshold", DEFAULT_LIFETIME_THRESHOLD))

func _get_base_mult_per_point() -> float:
	if not DataLoader.is_loaded:
		return DEFAULT_BASE_MULT_PER_POINT
	var p: Dictionary = DataLoader.balance.get("prestige", {}) as Dictionary
	return float(p.get("base_multiplier_per_point", DEFAULT_BASE_MULT_PER_POINT))
