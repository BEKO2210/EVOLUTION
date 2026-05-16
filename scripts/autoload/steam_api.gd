extends Node
##
## SteamAPI — thin wrapper around GodotSteam (when available) with safe
## no-op fallbacks when the Steam runtime is absent (running in editor,
## non-Steam launch, dev sandbox).
##
## Phase 1 / P1-002 stub. Real integration spike happens in P1-012:
##   1. Validate GodotSteam GDExtension works for our pinned Godot version
##      WITHOUT a custom engine build (preferred path).
##   2. Fallback: custom engine build if GDExtension doesn't carry through.
##   3. Test against Spacewar AppID 480: achievement trigger + cloud-save
##      round-trip across two machines.
##
## This stub exposes the API surface the rest of the game will call so
## downstream code can be written against a stable interface today.
##

# ----------------------------------------------------------------------------
# SIGNALS
# ----------------------------------------------------------------------------
signal initialized(success: bool, app_id: int)
signal achievement_set(achievement_id: String, success: bool)
signal cloud_synced(success: bool)

# ----------------------------------------------------------------------------
# STATE
# ----------------------------------------------------------------------------
var is_available: bool = false               ## true if Steam runtime + GodotSteam present
var app_id: int = 0                          ## set on init; 480 = Spacewar test, real AppID for release
var steam_user_id: int = 0                   ## populated on successful init
var steam_user_name: String = ""             ## populated on successful init

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Real GodotSteam detection happens in P1-012 spike.
	# For now we always return is_available=false so consumers safely no-op.
	is_available = false

# ----------------------------------------------------------------------------
# PUBLIC API — stubs
# ----------------------------------------------------------------------------

## Initialize Steam connection with the given AppID.
## Stub: real call delegates to GodotSteam.steamInit(app_id) in P1-012.
func initialize(target_app_id: int) -> bool:
	app_id = target_app_id
	is_available = false  # flip true once GodotSteam binds successfully
	initialized.emit(is_available, app_id)
	return is_available

## Trigger a Steam Achievement.
## Stub: no-op if !is_available. Real call: GodotSteam.setAchievement(id).
func set_achievement(achievement_id: String) -> bool:
	if not is_available:
		return false
	# TODO P1-012: Steam.setAchievement(achievement_id); Steam.storeStats()
	achievement_set.emit(achievement_id, true)
	return true

## Save a string to Steam Cloud under a given remote filename.
## Stub.
func cloud_save_text(_remote_path: String, _content: String) -> bool:
	if not is_available:
		return false
	# TODO P1-012: Steam.fileWrite(remote_path, content.to_utf8_buffer())
	cloud_synced.emit(true)
	return true

## Read a previously saved Cloud file. Returns empty string if absent.
## Stub.
func cloud_load_text(_remote_path: String) -> String:
	if not is_available:
		return ""
	# TODO P1-012: Steam.fileRead(remote_path) -> bytes -> string
	return ""

## Set Rich Presence string ("Spielt als Bakterium (Stage 5)") — optional, post-MVP.
func set_rich_presence(_key: String, _value: String) -> void:
	if not is_available:
		return
	# TODO Phase 7 polish
	pass
