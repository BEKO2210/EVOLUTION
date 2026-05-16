extends ScrollContainer
##
## Generic upgrade panel — auto or click. Populated from DataLoader at _ready.
##
## Phase 1 / P1-011. One instance per upgrade kind, configured via the
## `upgrade_kind` export.
##
## Each child UpgradeCard subscribes to its own signals; this panel just
## owns the list and unlock-gating (a card is only shown after the previous
## tier has count >= 1, matching the prototype's progressive reveal).
##

const UpgradeCardScene := preload("res://scenes/ui/upgrade_card.tscn")

@export_enum("auto", "click") var upgrade_kind: String = "auto"

@onready var _vbox: VBoxContainer = $VBox

var _cards: Array = []  # ordered by tier; element type UpgradeCard

func _ready() -> void:
	_build_cards()
	GameState.upgrade_count_changed.connect(_on_upgrade_count_changed)
	_apply_unlock_gating()

func _build_cards() -> void:
	var items: Array = (DataLoader.upgrades_auto if upgrade_kind == "auto"
		else DataLoader.upgrades_click)
	for u in items:
		var id: String = String(u["id"])
		var card = UpgradeCardScene.instantiate()
		card.setup(id, upgrade_kind)
		_vbox.add_child(card)
		_cards.append(card)

# ----------------------------------------------------------------------------
# Unlock gating — hide upgrades whose unlock_after_id hasn't been bought.
# ----------------------------------------------------------------------------
func _apply_unlock_gating() -> void:
	for card in _cards:
		var data: Variant = (DataLoader.get_upgrade_auto(card.upgrade_id) if upgrade_kind == "auto"
			else DataLoader.get_upgrade_click(card.upgrade_id))
		if data == null:
			continue
		var unlock_after: Variant = (data as Dictionary).get("unlock_after_id", null)
		if unlock_after == null:
			card.visible = true
			continue
		var prev_count: int = UpgradeSystem.get_count(String(unlock_after))
		card.visible = prev_count >= 1

func _on_upgrade_count_changed(_upgrade_id: String, _new_count: int) -> void:
	_apply_unlock_gating()
