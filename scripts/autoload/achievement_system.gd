extends Node
##
## AchievementSystem — declarative achievement evaluation + persistence.
##
## Phase 1 / P1-009.
##
## Source of truth:
##   data/achievements.json (loaded by DataLoader)
##     - condition.kind     — predicate to evaluate (one of nine known kinds)
##     - condition.threshold — numeric bound
##     - reward.*           — multipliers applied by UpgradeSystem.recalc_stats
##                            (click_multiplier, dps_multiplier, all_multiplier,
##                             crit_chance_add, golden_*)
##
## State:
##   GameState.achievements_unlocked: Dictionary[id -> unix_timestamp]
##
## Triggers:
##   Subscribes to every signal that could cause a condition to flip:
##     GameState.dna_changed         (lifetime_dna_at_least)
##     GameState.stage_changed       (stage_at_least)
##     GameState.prestige_performed  (prestige_points_at_least, divisions_at_least)
##     UpgradeSystem.upgrade_purchased (all_auto/click_upgrades_owned)
##     ClickSystem.click_landed      (total_clicks_at_least, total_crits_at_least)
##     SaveSystem.load_completed     (re-check after load fills GameState)
##
## On unlock:
##   1. Records GameState.achievements_unlocked[id] = unix_timestamp
##   2. Emits GameState.achievement_unlocked(id) — toast UI subscribes in P1-011
##   3. Calls UpgradeSystem.recalc_stats() so reward multipliers apply NOW
##

# ----------------------------------------------------------------------------
# CONDITION-KIND ENUM (mirrors data/schema-notes.md + DataLoader allowlist)
# ----------------------------------------------------------------------------
const KIND_TOTAL_CLICKS: String = "total_clicks_at_least"
const KIND_LIFETIME_DNA: String = "lifetime_dna_at_least"
const KIND_STAGE: String = "stage_at_least"
const KIND_TOTAL_CRITS: String = "total_crits_at_least"
const KIND_TOTAL_GOLDENS: String = "total_goldens_at_least"
const KIND_DIVISIONS: String = "divisions_at_least"
const KIND_PRESTIGE_POINTS: String = "prestige_points_at_least"
const KIND_ALL_AUTO: String = "all_auto_upgrades_owned"
const KIND_ALL_CLICK: String = "all_click_upgrades_owned"

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# All upstream signal sources are autoloaded BEFORE AchievementSystem
	# (see project.godot ordering — Achievement is added at the end of the
	# system block).
	GameState.dna_changed.connect(_on_dna_changed)
	GameState.stage_changed.connect(_on_stage_changed)
	GameState.prestige_performed.connect(_on_prestige_performed)
	UpgradeSystem.upgrade_purchased.connect(_on_upgrade_purchased)
	ClickSystem.click_landed.connect(_on_click_landed)
	SaveSystem.load_completed.connect(_on_load_completed)
	# Sweep once at boot in case GameState was populated synchronously before
	# we hooked up (defensive — currently a no-op on fresh boot).
	check_all()

# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

## True if the achievement has been unlocked this lifetime (across prestiges).
func is_unlocked(achievement_id: String) -> bool:
	return GameState.achievements_unlocked.has(achievement_id)

func get_unlocked_count() -> int:
	return GameState.achievements_unlocked.size()

func get_total_count() -> int:
	if not DataLoader.is_loaded:
		return 0
	return DataLoader.achievements.size()

## Re-evaluate every achievement's condition; unlock any whose predicate is
## now true. Returns the number of newly-unlocked achievements.
## Safe + idempotent — already-unlocked entries are skipped.
func check_all() -> int:
	if not DataLoader.is_loaded:
		return 0
	var unlocked_this_pass: int = 0
	for ach in DataLoader.achievements:
		var id: String = String(ach["id"])
		if GameState.achievements_unlocked.has(id):
			continue
		var cond: Dictionary = ach["condition"] as Dictionary
		if _evaluate_condition(cond):
			_unlock(ach)
			unlocked_this_pass += 1
	if unlocked_this_pass > 0:
		# Reward multipliers shift dps/click_power; recalc once at end of
		# the batch instead of per-unlock.
		UpgradeSystem.recalc_stats()
	return unlocked_this_pass

## Aggregate achievement reward multipliers as a Dictionary:
##   { "dps_mult": float, "click_mult": float, "all_mult": float,
##     "crit_chance_add": float, "golden_spawn_rate": float,
##     "golden_reward_mult": float }
## Returns the neutral identity when nothing is unlocked.
## Consumed by UpgradeSystem.recalc_stats and ClickSystem._get_crit_chance.
func get_reward_multipliers() -> Dictionary:
	var out: Dictionary = {
		"dps_mult": 1.0,
		"click_mult": 1.0,
		"all_mult": 1.0,
		"crit_chance_add": 0.0,
		"golden_spawn_rate": 1.0,
		"golden_reward_mult": 1.0,
	}
	if not DataLoader.is_loaded:
		return out
	for id in GameState.achievements_unlocked.keys():
		var ach: Variant = DataLoader.get_achievement(String(id))
		if ach == null:
			continue
		var reward: Dictionary = (ach as Dictionary).get("reward", {}) as Dictionary
		if reward.has("dps_multiplier"):
			out["dps_mult"] *= float(reward["dps_multiplier"])
		if reward.has("click_multiplier"):
			out["click_mult"] *= float(reward["click_multiplier"])
		if reward.has("all_multiplier"):
			out["all_mult"] *= float(reward["all_multiplier"])
		if reward.has("crit_chance_add"):
			out["crit_chance_add"] += float(reward["crit_chance_add"])
		if reward.has("golden_spawn_rate"):
			out["golden_spawn_rate"] *= float(reward["golden_spawn_rate"])
		if reward.has("golden_reward_multiplier"):
			out["golden_reward_mult"] *= float(reward["golden_reward_multiplier"])
	return out

# ----------------------------------------------------------------------------
# INTERNAL — predicate evaluation
# ----------------------------------------------------------------------------

func _evaluate_condition(cond: Dictionary) -> bool:
	var kind: String = String(cond.get("kind", ""))
	var thresh: float = float(cond.get("threshold", 0.0))
	match kind:
		KIND_TOTAL_CLICKS:
			return float(GameState.total_clicks) >= thresh
		KIND_LIFETIME_DNA:
			return GameState.lifetime_dna >= thresh
		KIND_STAGE:
			return float(GameState.stage) >= thresh
		KIND_TOTAL_CRITS:
			return float(GameState.total_crits) >= thresh
		KIND_TOTAL_GOLDENS:
			return float(GameState.total_goldens) >= thresh
		KIND_DIVISIONS:
			return float(GameState.divisions) >= thresh
		KIND_PRESTIGE_POINTS:
			return float(GameState.prestige_points) >= thresh
		KIND_ALL_AUTO:
			for u in DataLoader.upgrades_auto:
				if int(GameState.upgrade_counts.get(u["id"], 0)) < 1:
					return false
			return true
		KIND_ALL_CLICK:
			for u in DataLoader.upgrades_click:
				if int(GameState.upgrade_counts.get(u["id"], 0)) < 1:
					return false
			return true
		_:
			push_warning("[AchievementSystem] unknown condition.kind '%s'" % kind)
			return false

func _unlock(ach: Dictionary) -> void:
	var id: String = String(ach["id"])
	GameState.achievements_unlocked[id] = int(Time.get_unix_time_from_system())
	GameState.achievement_unlocked.emit(id)

# ----------------------------------------------------------------------------
# SIGNAL HANDLERS
# ----------------------------------------------------------------------------

func _on_dna_changed(_new_dna: float, _delta: float) -> void:
	check_all()

func _on_stage_changed(_new_stage: int, _old_stage: int) -> void:
	check_all()

func _on_prestige_performed(_gained: int) -> void:
	check_all()

func _on_upgrade_purchased(_upgrade_id: String, _new_count: int, _total_cost: float) -> void:
	check_all()

func _on_click_landed(_amount: float, _pos: Vector2, _is_crit: bool, _combo: int) -> void:
	check_all()

func _on_load_completed(_slot: int, success: bool) -> void:
	# After a successful load, the loaded state may already satisfy
	# achievements (e.g. balance update added a new achievement we now
	# qualify for retroactively). Sweep once.
	if success:
		check_all()
