extends Node
##
## UpgradeSystem — buying, cost math, milestone doubling, stats recalc.
##
## Phase 1 / P1-006.
##
## Source of truth:
##   data/upgrades_auto.json / upgrades_click.json (loaded by DataLoader)
##   data/balance_constants.json economy.{cost_growth, milestone_thresholds,
##                                        milestone_multiplier}
## State:
##   GameState.upgrade_counts[upgrade_id] -> int
##   GameState.dps and click_power are derived (recalc_stats writes them)
##
## On every owned-count change we run recalc_stats() which loops the
## DataLoader tables once. Inexpensive at 30+30 upgrades.
##
## DPS accumulation:
##   _on_logic_tick subscribes to TickSystem.logic_tick and converts
##   GameState.dps into DNA via GameState.add_dna(dps * dt). This is the
##   single accumulation point — no other system writes DNA from DPS.
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal upgrade_purchased(upgrade_id: String, new_count: int, total_cost: float)
signal milestone_crossed(upgrade_id: String, milestone: int, new_count: int)
signal stats_recalculated(dps: float, click_power: float)

# ----------------------------------------------------------------------------
# DEFAULTS (used until DataLoader has populated `balance`)
# ----------------------------------------------------------------------------
const COST_GROWTH_DEFAULT: float = 1.15
const MILESTONES_DEFAULT: Array = [10, 25, 50, 100]
const MILESTONE_MULTIPLIER_DEFAULT: float = 2.0

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Autoload order in project.godot guarantees TickSystem is initialized
	# before UpgradeSystem (UpgradeSystem comes after it).
	TickSystem.logic_tick.connect(_on_logic_tick)
	# Initial recalc so dps/click_power reflect any loaded save.
	recalc_stats()

# ----------------------------------------------------------------------------
# PUBLIC API — queries
# ----------------------------------------------------------------------------

## Count of a specific upgrade currently owned by the player.
func get_count(upgrade_id: String) -> int:
	return int(GameState.upgrade_counts.get(upgrade_id, 0))

## Current cost to buy ONE more of this upgrade.
## Returns 0 if upgrade_id is unknown — caller should validate.
func get_cost(upgrade_id: String) -> float:
	var data: Variant = _get_upgrade_data(upgrade_id)
	if data == null:
		return 0.0
	var count: int = get_count(upgrade_id)
	var growth: float = _get_cost_growth()
	return float(data["cost_base"]) * pow(growth, count)

## Geometric-series sum: cost to buy `count_to_buy` upgrades in a row.
##   sum = cost_at(n) * (growth^count_to_buy - 1) / (growth - 1)
## where cost_at(n) = cost_base * growth^current_count.
func get_bulk_cost(upgrade_id: String, count_to_buy: int) -> float:
	if count_to_buy <= 0:
		return 0.0
	var data: Variant = _get_upgrade_data(upgrade_id)
	if data == null:
		return 0.0
	var growth: float = _get_cost_growth()
	var start_cost: float = float(data["cost_base"]) * pow(growth, get_count(upgrade_id))
	return start_cost * (pow(growth, count_to_buy) - 1.0) / (growth - 1.0)

## How many of this upgrade can the player afford right now?
## Solves get_bulk_cost(upgrade_id, n) <= GameState.dna for max n.
func get_max_affordable(upgrade_id: String) -> int:
	var data: Variant = _get_upgrade_data(upgrade_id)
	if data == null:
		return 0
	var growth: float = _get_cost_growth()
	var start_cost: float = float(data["cost_base"]) * pow(growth, get_count(upgrade_id))
	if GameState.dna < start_cost:
		return 0
	# n = log(1 + dna * (g-1) / start) / log(g)
	var n_f: float = log(1.0 + GameState.dna * (growth - 1.0) / start_cost) / log(growth)
	return max(0, int(floor(n_f)))

func can_afford(upgrade_id: String) -> bool:
	return GameState.dna >= get_cost(upgrade_id)

## Milestone multiplier for a given count: ×2 at 10, again at 25, 50, 100.
## Result compounds: ×16 at count >= 100.
func get_milestone_multiplier(count: int) -> float:
	var m: float = 1.0
	var per_milestone: float = _get_milestone_multiplier()
	for threshold in _get_milestones():
		if count >= int(threshold):
			m *= per_milestone
	return m

# ----------------------------------------------------------------------------
# PUBLIC API — mutations
# ----------------------------------------------------------------------------

## Buy 1 of the given upgrade. Returns true on success.
func buy(upgrade_id: String) -> bool:
	return buy_bulk(upgrade_id, 1)

## Buy n of the given upgrade in a single transaction. Returns true if all
## n could be bought. If insufficient DNA, buys 0 and returns false.
func buy_bulk(upgrade_id: String, n: int) -> bool:
	if n <= 0:
		return false
	var data: Variant = _get_upgrade_data(upgrade_id)
	if data == null:
		return false
	var cost: float = get_bulk_cost(upgrade_id, n)
	if not GameState.spend_dna(cost):
		return false
	var old_count: int = get_count(upgrade_id)
	var new_count: int = old_count + n
	GameState.upgrade_counts[upgrade_id] = new_count
	GameState.upgrade_count_changed.emit(upgrade_id, new_count)
	upgrade_purchased.emit(upgrade_id, new_count, cost)
	# Fire milestone signal for every threshold crossed by this purchase.
	for threshold in _get_milestones():
		var ms: int = int(threshold)
		if old_count < ms and new_count >= ms:
			milestone_crossed.emit(upgrade_id, ms, new_count)
	recalc_stats()
	return true

## Buy max-affordable in one transaction. Returns the count actually bought.
func buy_max(upgrade_id: String) -> int:
	var n: int = get_max_affordable(upgrade_id)
	if n <= 0:
		return 0
	if buy_bulk(upgrade_id, n):
		return n
	return 0

## Recompute GameState.dps and GameState.click_power from owned counts.
## Cheap — single pass over both upgrade tables (60 items in v1).
## Pure function w.r.t. GameState.upgrade_counts; writes only dps & click_power.
##
## Phase-1 formula (research / achievement / mutation / prestige multipliers
## come in P1-007..P1-009):
##   dps         = sum over auto:  dps_base   * count * milestone_mult(count)
##   click_power = 1 + sum click:  click_base * count * milestone_mult(count)
func recalc_stats() -> void:
	if not DataLoader.is_loaded:
		return
	var dps_total: float = 0.0
	for u in DataLoader.upgrades_auto:
		var id: String = String(u["id"])
		var count: int = get_count(id)
		if count == 0:
			continue
		dps_total += float(u["dps_base"]) * float(count) * get_milestone_multiplier(count)
	var click_total: float = 1.0
	for u in DataLoader.upgrades_click:
		var id: String = String(u["id"])
		var count: int = get_count(id)
		if count == 0:
			continue
		click_total += float(u["click_power_base"]) * float(count) * get_milestone_multiplier(count)
	GameState.dps = dps_total
	GameState.click_power = click_total
	stats_recalculated.emit(dps_total, click_total)

# ----------------------------------------------------------------------------
# INTERNAL
# ----------------------------------------------------------------------------

func _on_logic_tick(dt: float) -> void:
	# Single accumulation point: DPS -> DNA at 4 Hz.
	if GameState.dps > 0.0 and dt > 0.0:
		GameState.add_dna(GameState.dps * dt)

func _get_upgrade_data(upgrade_id: String) -> Variant:
	var u: Variant = DataLoader.get_upgrade_auto(upgrade_id)
	if u != null:
		return u
	return DataLoader.get_upgrade_click(upgrade_id)

func _get_cost_growth() -> float:
	if not DataLoader.is_loaded:
		return COST_GROWTH_DEFAULT
	return float((DataLoader.balance.get("economy", {}) as Dictionary).get(
		"cost_growth", COST_GROWTH_DEFAULT))

func _get_milestones() -> Array:
	if not DataLoader.is_loaded:
		return MILESTONES_DEFAULT
	return (DataLoader.balance.get("economy", {}) as Dictionary).get(
		"milestone_thresholds", MILESTONES_DEFAULT)

func _get_milestone_multiplier() -> float:
	if not DataLoader.is_loaded:
		return MILESTONE_MULTIPLIER_DEFAULT
	return float((DataLoader.balance.get("economy", {}) as Dictionary).get(
		"milestone_multiplier", MILESTONE_MULTIPLIER_DEFAULT))
