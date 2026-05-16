extends Node
##
## AudioManager — bus routing, music layering, SFX dispatch.
##
## Phase 1 / P1-002. Stub interface only — real impl in P1-011 (UI greybox)
## and Phase 2 (audio production).
##
## Bus structure (configured in P1-011):
##   Master
##   ├── Music    (slider: music volume)
##   ├── SFX      (slider: SFX volume)
##   │   ├── Click
##   │   ├── UI
##   │   └── Stage
##   └── Ambient  (slider: optional)
##
## Music layering (4 layers, crossfade per stage range):
##   drone   — always (stage 1+)
##   pad     — fade in from stage 5
##   melody  — fade in from stage 12
##   tension — fade in from stage 23 + during stage transitions
##

# ----------------------------------------------------------------------------
# CONSTANTS — bus names. Real bus layout set in default_bus_layout.tres (P1-011).
# ----------------------------------------------------------------------------
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_AMBIENT: String = "Ambient"

const LAYER_DRONE: String = "drone"
const LAYER_PAD: String = "pad"
const LAYER_MELODY: String = "melody"
const LAYER_TENSION: String = "tension"

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Real bus + AudioStreamPlayer setup in P1-011.
	pass

# ----------------------------------------------------------------------------
# PUBLIC API — stubs
# ----------------------------------------------------------------------------

## Play a one-shot SFX by ID (e.g. "click_standard", "ui_buy", "stage_up").
## Stub: real impl resolves ID -> AudioStreamPlayer pool in P1-011/Phase-2.
func play_sfx(_sfx_id: String) -> void:
	if not GameState.sound:
		return
	# no-op until P1-011

## Set normalized volume (0..1) for a bus.
## Stub forwards to AudioServer once buses exist.
func set_bus_volume(bus_name: String, volume_01: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		# Bus not yet defined — no-op during P1-002.
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(volume_01, 0.0, 1.0)))

## Fade a music layer in/out (0..1). Used by stage progression.
func set_layer_volume(_layer_id: String, _volume_01: float) -> void:
	# Stub. Music layering implementation in Phase 2.
	pass

## Stop everything (e.g. on app pause).
func stop_all() -> void:
	pass
