extends Node
##
## ClickSystem — player-tap handling with combo + crit.
##
## Phase 1 / P1-006.
##
## Public entry point is `register_click(at_screen_pos)`. UI (P1-011) calls
## this when the cell is tapped; the smoke-test in main.gd calls it
## directly. ClickSystem owns the combo counter and crit roll; it writes
## DNA via GameState.add_dna() and emits `click_landed(amount, pos, crit)`
## so the FX layer can spawn float-text / ripples without coupling.
##
## Sources:
##   GameState.click_power  (derived by UpgradeSystem.recalc_stats)
##   data/balance_constants.json combo.* and crit.*
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal click_landed(amount: float, screen_pos: Vector2, is_crit: bool, combo_count: int)

# ----------------------------------------------------------------------------
# DEFAULTS — used until DataLoader balance is available.
# ----------------------------------------------------------------------------
const DEFAULT_COMBO_WINDOW_MS: int = 1500
const DEFAULT_COMBO_CAP: int = 60
const DEFAULT_COMBO_BASE_MAX_MULT: float = 3.0
const DEFAULT_COMBO_RAMP_START: int = 3
const DEFAULT_COMBO_RAMP_END: int = 30
const DEFAULT_CRIT_CHANCE: float = 0.05
const DEFAULT_CRIT_CHANCE_CAP: float = 0.95
const DEFAULT_CRIT_MULTIPLIER: float = 5.0

# ----------------------------------------------------------------------------
# STATE
# ----------------------------------------------------------------------------
var _combo_count: int = 0
var _combo_last_ms: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	_rng.randomize()

# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

## Process one player tap. Updates combo, rolls crit, adds DNA, emits signal.
## `at_screen_pos` is just passed through to listeners for FX placement.
func register_click(at_screen_pos: Vector2 = Vector2.ZERO) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var window_ms: int = _get_combo_window_ms()
	if now_ms - _combo_last_ms <= window_ms:
		_combo_count = min(_combo_count + 1, _get_combo_cap())
	else:
		_combo_count = 1
	_combo_last_ms = now_ms

	var combo_mult: float = _compute_combo_multiplier(_combo_count)
	var is_crit: bool = _rng.randf() < _get_crit_chance()
	var crit_mult: float = _get_crit_multiplier() if is_crit else 1.0

	var amount: float = GameState.click_power * combo_mult * crit_mult
	GameState.add_dna(amount)
	GameState.total_clicks += 1
	if is_crit:
		GameState.total_crits += 1

	click_landed.emit(amount, at_screen_pos, is_crit, _combo_count)

## Force-reset combo (used by pause/resume/prestige in later tickets).
func reset_combo() -> void:
	_combo_count = 0
	_combo_last_ms = 0

## Read-only view for HUD.
func get_combo_count() -> int:
	return _combo_count

func get_combo_multiplier() -> float:
	return _compute_combo_multiplier(_combo_count)

# ----------------------------------------------------------------------------
# INTERNAL
# ----------------------------------------------------------------------------

func _compute_combo_multiplier(combo: int) -> float:
	var ramp_start: int = _get_combo_ramp_start()
	var ramp_end: int = _get_combo_ramp_end()
	if combo < ramp_start:
		return 1.0
	var max_mult: float = _get_combo_base_max()
	var span: int = max(1, ramp_end - ramp_start)
	var t: float = min(1.0, float(combo - ramp_start) / float(span))
	return 1.0 + (max_mult - 1.0) * t

func _balance_combo() -> Dictionary:
	if not DataLoader.is_loaded:
		return {}
	return DataLoader.balance.get("combo", {}) as Dictionary

func _balance_crit() -> Dictionary:
	if not DataLoader.is_loaded:
		return {}
	return DataLoader.balance.get("crit", {}) as Dictionary

func _get_combo_window_ms() -> int:
	return int(_balance_combo().get("time_window_ms", DEFAULT_COMBO_WINDOW_MS))

func _get_combo_cap() -> int:
	return int(_balance_combo().get("click_count_cap", DEFAULT_COMBO_CAP))

func _get_combo_base_max() -> float:
	return float(_balance_combo().get("base_max_multiplier", DEFAULT_COMBO_BASE_MAX_MULT))

func _get_combo_ramp_start() -> int:
	return int(_balance_combo().get("ramp_start_clicks", DEFAULT_COMBO_RAMP_START))

func _get_combo_ramp_end() -> int:
	return int(_balance_combo().get("ramp_end_clicks", DEFAULT_COMBO_RAMP_END))

func _get_crit_chance() -> float:
	var c: Dictionary = _balance_crit()
	var base: float = float(c.get("base_chance", DEFAULT_CRIT_CHANCE))
	var cap: float = float(c.get("max_chance", DEFAULT_CRIT_CHANCE_CAP))
	# Achievement bonus (P1-009). AchievementSystem may not exist yet during
	# early autoload init — guard.
	var ach_add: float = 0.0
	if get_node_or_null("/root/AchievementSystem") != null:
		ach_add = float(AchievementSystem.get_reward_multipliers().get("crit_chance_add", 0.0))
	# Research bonuses come in their own ticket.
	return min(cap, base + ach_add)

func _get_crit_multiplier() -> float:
	return float(_balance_crit().get("base_multiplier", DEFAULT_CRIT_MULTIPLIER))
