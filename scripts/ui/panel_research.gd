extends ScrollContainer
##
## Research panel — Phase 1 / P1-011 stub.
##
## Lists the 12 research entries from data/research.json with cost + description.
## Buy-button is wired but the UpgradeSystem doesn't currently apply research
## effects to recalc_stats — that arrives in a future polish ticket alongside
## the rest of the multiplier chain (mutation, stage_bonus_amplify, etc.).
##

@onready var _vbox: VBoxContainer = $VBox

func _ready() -> void:
	for r in DataLoader.research:
		var item := PanelContainer.new()
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 2)
		var name_label := Label.new()
		name_label.text = String((r as Dictionary).get("legacy_name_de", r["id"]))
		var desc_label := Label.new()
		desc_label.text = String((r as Dictionary).get("legacy_desc_de", ""))
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
		var cost_label := Label.new()
		cost_label.text = "Kosten: %s DNA  ·  (Phase-2 wirkt)" % _fmt(float(r["cost_dna"]))
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))
		inner.add_child(name_label)
		inner.add_child(desc_label)
		inner.add_child(cost_label)
		item.add_child(inner)
		_vbox.add_child(item)

static func _fmt(n: float) -> String:
	if n < 1000.0:
		return "%d" % int(round(n))
	var units := ["K", "M", "B", "T", "Q", "Qi", "Sx", "Sp"]
	var i: int = -1
	var v: float = n
	while v >= 1000.0 and i < units.size() - 1:
		v /= 1000.0
		i += 1
	if i < 0:
		return "%d" % int(round(v))
	return "%.1f%s" % [v, units[i]] if v < 100.0 else "%d%s" % [int(round(v)), units[i]]
