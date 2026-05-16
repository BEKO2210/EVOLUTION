extends ScrollContainer
##
## Achievements panel — Phase 1 / P1-011.
##
## Grid (single-column for greybox simplicity) of all 27 achievements.
## Unlocked entries are highlighted; locked entries are dim. Reactively
## refreshes on the GameState.achievement_unlocked signal.
##

@onready var _vbox: VBoxContainer = $VBox

# Map achievement_id -> Label so we can in-place update on unlock.
var _row_labels: Dictionary = {}

func _ready() -> void:
	for ach in DataLoader.achievements:
		var row := _make_row(ach as Dictionary)
		_vbox.add_child(row)
	GameState.achievement_unlocked.connect(_on_achievement_unlocked)

func _make_row(ach: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var status := Label.new()
	status.text = _status_text(String(ach["id"]))
	status.custom_minimum_size = Vector2(28, 0)
	var name_label := Label.new()
	name_label.text = String(ach.get("legacy_name_de", ach["id"]))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(status)
	hbox.add_child(name_label)
	p.add_child(hbox)
	_row_labels[String(ach["id"])] = status
	# Dim if locked.
	_apply_dim(p, GameState.achievements_unlocked.has(String(ach["id"])))
	p.set_meta("achievement_id", String(ach["id"]))
	return p

func _on_achievement_unlocked(id: String) -> void:
	var label: Variant = _row_labels.get(id, null)
	if label != null:
		(label as Label).text = _status_text(id)
		# Find the parent PanelContainer and undim
		var p: Node = (label as Label).get_parent().get_parent() as Node
		if p is PanelContainer:
			_apply_dim(p as PanelContainer, true)

func _status_text(id: String) -> String:
	return "[✓]" if GameState.achievements_unlocked.has(id) else "[ ]"

func _apply_dim(node: PanelContainer, unlocked: bool) -> void:
	node.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.55, 0.55, 0.55, 1)
