extends PanelContainer
##
## UpgradeCard — single reusable component for an Auto or Click upgrade row.
##
## Phase 1 / P1-011. Greybox layout (no theming pass); the UX contract is:
##   - Shows upgrade name, owned count, current cost, dps/click base
##   - Buy button is enabled iff GameState.dna >= current cost
##   - Subscribes to GameState.dna_changed + UpgradeSystem.upgrade_purchased
##     so it stays live without a full panel rebuild
##
## Setup contract (called by the parent panel after instantiation):
##   var card := UpgradeCardScene.instantiate()
##   card.setup(upgrade_id, upgrade_kind)
##   container.add_child(card)
##
## upgrade_kind is "auto" or "click" — determines which data table the card
## reads (`dps_base` for auto, `click_power_base` for click).
##

const KIND_AUTO: String = "auto"
const KIND_CLICK: String = "click"

var upgrade_id: String = ""
var kind: String = KIND_AUTO
var _data: Dictionary = {}

@onready var _name_label: Label = $Margin/VBox/Row/NameVBox/NameLabel
@onready var _detail_label: Label = $Margin/VBox/Row/NameVBox/DetailLabel
@onready var _count_label: Label = $Margin/VBox/Row/RightVBox/CountLabel
@onready var _cost_label: Label = $Margin/VBox/Row/RightVBox/CostLabel
@onready var _buy_button: Button = $Margin/VBox/BuyButton

func setup(p_upgrade_id: String, p_kind: String) -> void:
	upgrade_id = p_upgrade_id
	kind = p_kind
	var data: Variant
	if kind == KIND_AUTO:
		data = DataLoader.get_upgrade_auto(upgrade_id)
	else:
		data = DataLoader.get_upgrade_click(upgrade_id)
	if data == null:
		push_error("[UpgradeCard] unknown upgrade %s (kind=%s)" % [upgrade_id, kind])
		return
	_data = data as Dictionary

func _ready() -> void:
	_buy_button.pressed.connect(_on_buy_pressed)
	GameState.dna_changed.connect(_on_dna_changed)
	UpgradeSystem.upgrade_purchased.connect(_on_upgrade_purchased)
	_refresh()

# ----------------------------------------------------------------------------
# UI refresh
# ----------------------------------------------------------------------------

func _refresh() -> void:
	if _data.is_empty():
		return
	# Name (legacy name from data file — final localization in Phase 3 via name_key)
	_name_label.text = String(_data.get("legacy_name_de", upgrade_id))
	# Detail: base output value
	var base_value: float
	if kind == KIND_AUTO:
		base_value = float(_data.get("dps_base", 0.0))
		_detail_label.text = "+%s DNA/s" % _fmt_short(base_value)
	else:
		base_value = float(_data.get("click_power_base", 0.0))
		_detail_label.text = "+%s pro Klick" % _fmt_short(base_value)
	# Count owned
	var count: int = UpgradeSystem.get_count(upgrade_id)
	_count_label.text = "×%d" % count
	# Current cost
	var cost: float = UpgradeSystem.get_cost(upgrade_id)
	_cost_label.text = "%s DNA" % _fmt_short(cost)
	# Affordable?
	var affordable: bool = UpgradeSystem.can_afford(upgrade_id)
	_buy_button.disabled = not affordable
	_buy_button.text = "Kaufen" if affordable else "Zu teuer"

# ----------------------------------------------------------------------------
# Signal handlers
# ----------------------------------------------------------------------------

func _on_buy_pressed() -> void:
	UpgradeSystem.buy(upgrade_id)
	# refresh happens via the upgrade_purchased signal handler below

func _on_dna_changed(_new_dna: float, _delta: float) -> void:
	# Just toggle the Buy button affordability cheaply — full refresh on buy.
	if _data.is_empty():
		return
	var affordable: bool = UpgradeSystem.can_afford(upgrade_id)
	_buy_button.disabled = not affordable
	_buy_button.text = "Kaufen" if affordable else "Zu teuer"

func _on_upgrade_purchased(purchased_id: String, _new_count: int, _cost: float) -> void:
	if purchased_id == upgrade_id:
		_refresh()

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

## Compact number formatting for the HUD. Matches the HTML prototype's
## "1K / 1M / 1B / 1T / ..." style so the visual identity carries over.
static func _fmt_short(n: float) -> String:
	if n < 0.0:
		return "-" + _fmt_short(-n)
	if n < 1000.0:
		return "%d" % int(round(n))
	var units := ["K", "M", "B", "T", "Q", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var i: int = -1
	var v: float = n
	while v >= 1000.0 and i < units.size() - 1:
		v /= 1000.0
		i += 1
	if i < 0:
		return "%d" % int(round(v))
	if v < 10.0:
		return "%.2f%s" % [v, units[i]]
	if v < 100.0:
		return "%.1f%s" % [v, units[i]]
	return "%d%s" % [int(round(v)), units[i]]
