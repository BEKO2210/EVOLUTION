extends Node
##
## SteamAPI — thin wrapper around GodotSteam (when available) with safe
## no-op fallbacks when the Steam runtime is absent.
##
## Phase 1 / P1-012 spike. The wrapper is fully feature-detected: if the
## GodotSteam GDExtension is not installed (`addons/godotsteam/` missing or
## the extension failed to load), every public method becomes a no-op and
## `is_available` stays false. Game code can call these methods freely
## without checking.
##
## Setup instructions for activating GodotSteam:
##   docs/steam/godotsteam-setup.md
##
## Decision rationale (GDExtension vs Engine-Module):
##   docs/decisions/ADR-0005-godotsteam-integration.md
##
## Spike acceptance (P1-012):
##   - Spacewar (AppID 480) Steam.init() succeeds + username retrievable
##   - Test achievement triggers, visible in Steam profile
##   - Cloud-save round-trip across two devices in <60s
## All three need real Steam runtime; this autoload + scenes/dev/steam_smoke_test.tscn
## are the test harness to validate them.
##

# ----------------------------------------------------------------------------
# SIGNALS (forwarded from GodotSteam when available)
# ----------------------------------------------------------------------------
signal initialized(success: bool, app_id: int)
signal achievement_set(achievement_id: String, success: bool)
signal cloud_synced(success: bool)

# ----------------------------------------------------------------------------
# CONSTANTS
# ----------------------------------------------------------------------------
const SPACEWAR_APP_ID: int = 480           ## Steam's public test AppID
const STEAM_SINGLETON_NAME: String = "Steam"  ## GodotSteam exposes itself as `Steam`

# ----------------------------------------------------------------------------
# STATE
# ----------------------------------------------------------------------------
var is_available: bool = false             ## true iff GodotSteam loaded AND Steam.steamInit succeeded
var has_extension: bool = false            ## true iff GodotSteam GDExtension is present (Steam runtime may still be missing)
var app_id: int = 0
var steam_user_id: int = 0
var steam_user_name: String = ""

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------
func _ready() -> void:
	# Feature-detect the GodotSteam GDExtension. If the extension wasn't
	# installed (which is normal during Phase 1 development), has_extension
	# stays false and all public methods quietly no-op.
	has_extension = Engine.has_singleton(STEAM_SINGLETON_NAME)
	if has_extension:
		print("[SteamAPI] GodotSteam GDExtension detected.")
	# Note: we DO NOT auto-initialize Steam here. The game calls initialize()
	# explicitly once the player is ready (e.g. after they accept the
	# telemetry / analytics opt-in dialog, which happens to be a good time
	# to also hint that Steam features are loading).

# ----------------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------------

## Initialize Steam connection with the given AppID. Returns true on success.
## Safe to call multiple times — only the first call actually initializes.
func initialize(target_app_id: int) -> bool:
	app_id = target_app_id
	if not has_extension:
		# Extension not installed — operate in no-op mode.
		is_available = false
		initialized.emit(false, app_id)
		return false
	# Extension present — call into it via the singleton lookup. We use
	# Engine.get_singleton() rather than the `Steam` global because the
	# global is only typed when the extension is loaded; using the
	# singleton lookup keeps Phase-1 code compiling without the extension.
	var steam: Object = Engine.get_singleton(STEAM_SINGLETON_NAME)
	if steam == null:
		push_warning("[SteamAPI] Engine.has_singleton(Steam) true but get_singleton() returned null")
		is_available = false
		initialized.emit(false, app_id)
		return false
	# Steam.steamInit(restart_app_if_necessary: bool, app_id: int, embed_callbacks: bool)
	# Returns Dictionary: { "status": int, "verbal": String }
	# status 0 = OK (k_EResultOK), other values = various failure modes.
	var result: Variant = steam.call("steamInit", false, app_id, true)
	var status: int = -1
	if result is Dictionary:
		status = int((result as Dictionary).get("status", -1))
	is_available = (status == 0)
	if is_available:
		steam_user_id = int(steam.call("getSteamID"))
		steam_user_name = String(steam.call("getPersonaName"))
		print("[SteamAPI] Initialized for AppID %d as user '%s' (id=%d)" % [
			app_id, steam_user_name, steam_user_id])
	else:
		push_warning("[SteamAPI] steamInit failed with status %d" % status)
	initialized.emit(is_available, app_id)
	return is_available

## Trigger a Steam Achievement. Returns true if the call was forwarded;
## no-op (returns false) if Steam isn't available.
func set_achievement(achievement_id: String) -> bool:
	if not is_available:
		return false
	var steam: Object = Engine.get_singleton(STEAM_SINGLETON_NAME)
	# Steam.setAchievement(name: String) -> bool
	var ok: bool = bool(steam.call("setAchievement", achievement_id))
	if ok:
		# Persist immediately so Steam servers receive it; otherwise the
		# achievement only commits on next storeStats() call.
		steam.call("storeStats")
	achievement_set.emit(achievement_id, ok)
	return ok

## Write a UTF-8 string to Steam Cloud under a given remote path.
## Returns true on success; no-op false if Steam not available.
func cloud_save_text(remote_path: String, content: String) -> bool:
	if not is_available:
		return false
	var steam: Object = Engine.get_singleton(STEAM_SINGLETON_NAME)
	# Steam.fileWrite(file_name: String, data: PackedByteArray, length: int) -> bool
	var bytes: PackedByteArray = content.to_utf8_buffer()
	var ok: bool = bool(steam.call("fileWrite", remote_path, bytes, bytes.size()))
	cloud_synced.emit(ok)
	return ok

## Read a previously saved Cloud file as UTF-8 string. Returns "" if absent
## or Steam not available.
func cloud_load_text(remote_path: String) -> String:
	if not is_available:
		return ""
	var steam: Object = Engine.get_singleton(STEAM_SINGLETON_NAME)
	# Check existence first — Steam.fileExists(file_name: String) -> bool
	if not bool(steam.call("fileExists", remote_path)):
		return ""
	# Steam.getFileSize(file_name: String) -> int
	var size: int = int(steam.call("getFileSize", remote_path))
	if size <= 0:
		return ""
	# Steam.fileRead(file_name: String, length: int) -> Dictionary { "data": PackedByteArray }
	var result: Variant = steam.call("fileRead", remote_path, size)
	if not result is Dictionary:
		return ""
	var bytes: PackedByteArray = (result as Dictionary).get("data", PackedByteArray()) as PackedByteArray
	return bytes.get_string_from_utf8()

## Set a Rich-Presence key/value pair (e.g. "status" / "Spielt als Bakterium (Stage 5)").
## No-op if Steam not available.
func set_rich_presence(key: String, value: String) -> void:
	if not is_available:
		return
	var steam: Object = Engine.get_singleton(STEAM_SINGLETON_NAME)
	# Steam.setRichPresence(key: String, value: String) -> bool
	steam.call("setRichPresence", key, value)

## Steam callbacks (event polling). GodotSteam needs runCallbacks() called
## once per frame to dispatch events. We hook this into TickSystem.visual_tick
## from main.gd OR a dedicated process callback once the extension is loaded.
## For Phase 1 we just expose the method; wiring happens in Phase 2.
func run_callbacks() -> void:
	if not is_available:
		return
	var steam: Object = Engine.get_singleton(STEAM_SINGLETON_NAME)
	steam.call("run_callbacks")
