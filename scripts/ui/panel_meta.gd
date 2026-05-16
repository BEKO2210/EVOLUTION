extends ScrollContainer
##
## Meta panel — Prestige + lifetime stats.
##
## Phase 1 / P1-011. Greybox: focused on functionality, not polish.
## Prestige button is the centerpiece (Akzeptanz: "Klick → Prestige").
##

@onready var _stage_label: Label = $VBox/StagesGroup/StagesVBox/StageLabel
@onready var _lifetime_label: Label = $VBox/StagesGroup/StagesVBox/LifetimeLabel
@onready var _clicks_label: Label = $VBox/StagesGroup/StagesVBox/ClicksLabel
@onready var _prestige_mult_label: Label = $VBox/PrestigeGroup/PrestigeVBox/MultLabel
@onready var _prestige_ep_label: Label = $VBox/PrestigeGroup/PrestigeVBox/EpLabel
@onready var _prestige_next_label: Label = $VBox/PrestigeGroup/PrestigeVBox/NextLabel
@onready var _prestige_button: Button = $VBox/PrestigeGroup/PrestigeVBox/PrestigeButton

func _ready() -> void:
	_prestige_button.pressed.connect(_on_prestige_pressed)
	GameState.dna_changed.connect(_refresh)
	GameState.stage_changed.connect(_on_stage_changed)
	GameState.prestige_performed.connect(_on_prestige_performed)
	_refresh()

func _refresh(_a = null, _b = null) -> void:
	_stage_label.text = "Stage: %d" % GameState.stage
	_lifetime_label.text = "Lifetime-DNA: %s" % _fmt(GameState.lifetime_dna)
	_clicks_label.text = "Klicks: %d" % GameState.total_clicks
	_prestige_mult_label.text = "Multiplier: ×%.2f" % GameState.prestige_multiplier
	var ep_available: int = PrestigeSystem.get_evolution_points_available()
	_prestige_ep_label.text = "EP verfügbar: %d (besessen: %d)" % [
		ep_available, GameState.prestige_points,
	]
	if ep_available > 0:
		_prestige_next_label.text = "Nach Prestige: ×%.2f" % PrestigeSystem.get_next_multiplier_after_prestige()
		_prestige_button.disabled = false
		_prestige_button.text = "Prestige (+%d EP)" % ep_available
	else:
		var needed: float = PrestigeSystem.get_lifetime_dna_needed_for_total_points(
			GameState.prestige_points + 1
		)
		_prestige_next_label.text = "Benötigt %s Lifetime-DNA für nächste EP" % _fmt(needed)
		_prestige_button.disabled = true
		_prestige_button.text = "Prestige (keine EP)"

func _on_stage_changed(_n: int, _o: int) -> void:
	_refresh()

func _on_prestige_performed(_gained: int) -> void:
	_refresh()

func _on_prestige_pressed() -> void:
	# Phase-1 greybox: no confirm dialog yet. Real UI gets that in Phase 2.
	# Acceptance criterion is "click triggers prestige", so we call directly.
	PrestigeSystem.do_prestige()

static func _fmt(n: float) -> String:
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
