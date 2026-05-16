extends PanelContainer
##
## HUD — top-of-screen header showing DNA, DPS, stage.
##
## Phase 1 / P1-011. Subscribes to the right signals so it never has to poll.
##

@onready var _dna_label: Label = $Margin/HBox/DnaVBox/DnaValue
@onready var _dps_label: Label = $Margin/HBox/DpsVBox/DpsValue
@onready var _stage_label: Label = $Margin/HBox/StageVBox/StageValue
@onready var _click_label: Label = $Margin/HBox/ClickVBox/ClickValue

func _ready() -> void:
	GameState.dna_changed.connect(_on_dna_changed)
	GameState.stage_changed.connect(_on_stage_changed)
	UpgradeSystem.stats_recalculated.connect(_on_stats_recalculated)
	_refresh()

func _refresh() -> void:
	_dna_label.text = _fmt(GameState.dna)
	_dps_label.text = "%s/s" % _fmt(GameState.dps)
	_stage_label.text = "%d" % GameState.stage
	_click_label.text = "+%s" % _fmt(GameState.click_power)

func _on_dna_changed(_new_dna: float, _delta: float) -> void:
	_dna_label.text = _fmt(GameState.dna)

func _on_stage_changed(new_stage: int, _old: int) -> void:
	_stage_label.text = "%d" % new_stage

func _on_stats_recalculated(dps: float, click_power: float) -> void:
	_dps_label.text = "%s/s" % _fmt(dps)
	_click_label.text = "+%s" % _fmt(click_power)

static func _fmt(n: float) -> String:
	if n < 0.0:
		return "-" + _fmt(-n)
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
