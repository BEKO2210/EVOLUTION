extends Control
##
## Steam smoke-test dev scene (Phase 1 / P1-012).
##
## Run manually after GodotSteam is installed (see docs/steam/godotsteam-setup.md):
##   F6 in the editor on scenes/dev/steam_smoke_test.tscn
##
## Provides one button per spike acceptance criterion:
##   - Init (Spacewar AppID 480)
##   - Show username + steam_id
##   - Trigger a test achievement
##   - Write a test file to Steam Cloud
##   - Read it back
##
## All buttons gracefully report "Steam not available" if the GDExtension
## isn't installed — so this scene is safe to commit + safe to open in a
## dev environment without Steam.
##

const TEST_CLOUD_PATH: String = "evolution_smoke_test.txt"
const TEST_ACHIEVEMENT_ID: String = "ACH_WIN_ONE_GAME"  # Built-in Spacewar achievement

@onready var _status_label: Label = $VBox/StatusLabel
@onready var _init_button: Button = $VBox/InitButton
@onready var _info_button: Button = $VBox/InfoButton
@onready var _achievement_button: Button = $VBox/AchievementButton
@onready var _cloud_write_button: Button = $VBox/CloudWriteButton
@onready var _cloud_read_button: Button = $VBox/CloudReadButton

func _ready() -> void:
	_init_button.pressed.connect(_on_init)
	_info_button.pressed.connect(_on_info)
	_achievement_button.pressed.connect(_on_achievement)
	_cloud_write_button.pressed.connect(_on_cloud_write)
	_cloud_read_button.pressed.connect(_on_cloud_read)
	_refresh_button_states()
	_log("Bereit. Klicke 'Init Steam' um zu starten.")
	if not SteamAPI.has_extension:
		_log("⚠️ GodotSteam-GDExtension nicht installiert.\n   Setup: docs/steam/godotsteam-setup.md")

# ----------------------------------------------------------------------------
# Button handlers
# ----------------------------------------------------------------------------

func _on_init() -> void:
	_log("→ Steam.init(AppID=%d)…" % SteamAPI.SPACEWAR_APP_ID)
	var ok: bool = SteamAPI.initialize(SteamAPI.SPACEWAR_APP_ID)
	if ok:
		_log("✅ Init OK")
	else:
		_log("❌ Init failed — siehe Output-Tab für Details")
	_refresh_button_states()

func _on_info() -> void:
	if not SteamAPI.is_available:
		_log("Steam nicht initialisiert.")
		return
	_log("User: %s\nSteamID: %d\nAppID: %d" % [
		SteamAPI.steam_user_name,
		SteamAPI.steam_user_id,
		SteamAPI.app_id,
	])

func _on_achievement() -> void:
	if not SteamAPI.is_available:
		_log("Steam nicht initialisiert.")
		return
	_log("→ Trigger '%s'…" % TEST_ACHIEVEMENT_ID)
	var ok: bool = SteamAPI.set_achievement(TEST_ACHIEVEMENT_ID)
	if ok:
		_log("✅ Achievement gesendet. Sollte sofort als Steam-Overlay-Toast erscheinen.")
	else:
		_log("❌ Achievement-Call failed")

func _on_cloud_write() -> void:
	if not SteamAPI.is_available:
		_log("Steam nicht initialisiert.")
		return
	var payload: String = "Hello Cloud at %d" % int(Time.get_unix_time_from_system())
	_log("→ Write '%s' → %s" % [payload, TEST_CLOUD_PATH])
	var ok: bool = SteamAPI.cloud_save_text(TEST_CLOUD_PATH, payload)
	if ok:
		_log("✅ Cloud-Write OK. Wartezeit bis Sync zu anderen Geräten: typisch 5–60 s.")
	else:
		_log("❌ Cloud-Write failed")

func _on_cloud_read() -> void:
	if not SteamAPI.is_available:
		_log("Steam nicht initialisiert.")
		return
	_log("→ Read %s…" % TEST_CLOUD_PATH)
	var content: String = SteamAPI.cloud_load_text(TEST_CLOUD_PATH)
	if content.is_empty():
		_log("(leer / nicht vorhanden)")
	else:
		_log("✅ Inhalt: %s" % content)

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

func _refresh_button_states() -> void:
	_info_button.disabled = not SteamAPI.is_available
	_achievement_button.disabled = not SteamAPI.is_available
	_cloud_write_button.disabled = not SteamAPI.is_available
	_cloud_read_button.disabled = not SteamAPI.is_available

func _log(msg: String) -> void:
	_status_label.text += "\n" + msg
	print("[SteamSmoke] " + msg)
