extends Node
##
## TickSystem — coordinates the game's two-rate update loop and triggers
## periodic auto-save.
##
## Phase 1 / P1-005.
##
## Architecture:
##
##   Logic tick   — 4 Hz (every 250 ms) via a Timer with PROCESS_MODE_ALWAYS.
##                  Emits  `logic_tick(dt_seconds: float)`.
##                  Used for: DPS accumulation, mutation/golden spawn checks,
##                  achievement-predicate evaluation. Fires consistently even
##                  while the SceneTree itself is paused (e.g. a settings
##                  popup) because "game time" should not freeze for that.
##
##   Visual tick  — per-frame via `_process(delta)`.
##                  Emits  `visual_tick(dt_seconds: float)`.
##                  Used for: cell animation, UI lerps, FX layer.
##                  Stops when SceneTree is paused (this is intentional —
##                  visuals don't need to update while a modal is open).
##
##   Auto-save    — separate Timer at `save_interval_ms` (from
##                  data/balance_constants.json:tick_rates, default 15 s).
##                  Calls SaveSystem.save(SLOT_CLOUD) and emits
##                  `auto_save_fired`. Can be disabled via
##                  set_auto_save_enabled(false) for tests.
##
## Pause model:
##   - `pause()` / `resume()`     — TickSystem-local; halts BOTH logic and
##                                  visual tick + auto-save (player-initiated
##                                  game pause).
##   - `get_tree().paused = true` — engine-wide; halts visual tick only,
##                                  logic continues (modal popups in-game).
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal logic_tick(dt_seconds: float)
signal visual_tick(dt_seconds: float)
signal auto_save_fired()

# ----------------------------------------------------------------------------
# DEFAULTS (used until DataLoader has populated `balance`)
# ----------------------------------------------------------------------------
const DEFAULT_LOGIC_INTERVAL_S: float = 0.25
const DEFAULT_SAVE_INTERVAL_S: float = 15.0

# ----------------------------------------------------------------------------
# STATE
# ----------------------------------------------------------------------------
var _logic_timer: Timer
var _save_timer: Timer
var _is_running: bool = false
var _auto_save_enabled: bool = true

## Tick counters (public for debug HUD / smoke tests).
var logic_tick_count: int = 0
var visual_tick_count: int = 0
var auto_save_count: int = 0

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	var logic_interval_s: float = DEFAULT_LOGIC_INTERVAL_S
	var save_interval_s: float = DEFAULT_SAVE_INTERVAL_S
	if DataLoader.is_loaded and DataLoader.balance.has("tick_rates"):
		var tick_rates: Dictionary = DataLoader.balance["tick_rates"]
		var l_ms: float = float(tick_rates.get("logic_tick_interval_ms", 250))
		var s_ms: float = float(tick_rates.get("save_interval_ms", 15000))
		logic_interval_s = max(0.01, l_ms / 1000.0)
		save_interval_s = max(0.1, s_ms / 1000.0)

	_logic_timer = _make_timer("LogicTimer", logic_interval_s, _on_logic_timer_timeout)
	_save_timer = _make_timer("AutoSaveTimer", save_interval_s, _on_save_timer_timeout)
	_is_running = true

func _process(delta: float) -> void:
	# `_process` only fires if scene-tree isn't paused or this node is
	# PROCESS_MODE_ALWAYS. Either way, gate on _is_running to support
	# our local pause() / resume().
	if not _is_running:
		return
	visual_tick_count += 1
	visual_tick.emit(delta)

# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

## Halt both ticks AND auto-save (player-initiated game pause).
func pause() -> void:
	if not _is_running:
		return
	_is_running = false
	if _logic_timer:
		_logic_timer.stop()
	if _save_timer:
		_save_timer.stop()

## Resume after a previous pause().
func resume() -> void:
	if _is_running:
		return
	_is_running = true
	if _logic_timer:
		_logic_timer.start()
	if _save_timer:
		_save_timer.start()

## Enable / disable periodic auto-save without affecting the tick loops.
## Used by tests to avoid touching the player's real save slots.
func set_auto_save_enabled(enabled: bool) -> void:
	_auto_save_enabled = enabled

## True if either tick loop is currently running.
func is_running() -> bool:
	return _is_running

## True if auto-save will fire when its timer ticks.
func is_auto_save_enabled() -> bool:
	return _auto_save_enabled

## Currently configured interval between logic ticks (seconds).
func get_logic_interval_s() -> float:
	if _logic_timer == null:
		return DEFAULT_LOGIC_INTERVAL_S
	return _logic_timer.wait_time

## Currently configured interval between auto-saves (seconds).
func get_save_interval_s() -> float:
	if _save_timer == null:
		return DEFAULT_SAVE_INTERVAL_S
	return _save_timer.wait_time

# ----------------------------------------------------------------------------
# INTERNAL
# ----------------------------------------------------------------------------

func _make_timer(timer_name: String, interval_s: float, on_timeout: Callable) -> Timer:
	var t: Timer = Timer.new()
	t.name = timer_name
	t.wait_time = interval_s
	t.autostart = true
	t.one_shot = false
	# Run on PHYSICS to be deterministic w.r.t. _physics_process; not strictly
	# required, but pairs well with the game's logic step semantics.
	t.process_callback = Timer.TIMER_PROCESS_PHYSICS
	# ALWAYS so a modal scene-tree pause doesn't freeze game time.
	t.process_mode = Node.PROCESS_MODE_ALWAYS
	t.timeout.connect(on_timeout)
	add_child(t)
	return t

func _on_logic_timer_timeout() -> void:
	if not _is_running:
		return
	logic_tick_count += 1
	logic_tick.emit(_logic_timer.wait_time)

func _on_save_timer_timeout() -> void:
	if not _is_running:
		return
	if not _auto_save_enabled:
		return
	auto_save_count += 1
	SaveSystem.save(SaveSystem.SLOT_CLOUD)
	auto_save_fired.emit()
