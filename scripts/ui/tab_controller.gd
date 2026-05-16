extends VBoxContainer
##
## TabController — top-level UI shell that switches between the five panels.
##
## Phase 1 / P1-011. Uses TabContainer under the hood — minimal greybox; the
## final stylized tab bar lands in Phase 2.
##

const PanelUpgradesScene := preload("res://scenes/ui/panel_upgrades.tscn")
const PanelMetaScene := preload("res://scenes/ui/panel_meta.tscn")
const PanelResearchScene := preload("res://scenes/ui/panel_research.tscn")
const PanelAchievementsScene := preload("res://scenes/ui/panel_achievements.tscn")

@onready var _tab_container: TabContainer = $TabContainer

func _ready() -> void:
	# Auto tab
	var auto_panel = PanelUpgradesScene.instantiate()
	auto_panel.upgrade_kind = "auto"
	auto_panel.name = "Auto"
	_tab_container.add_child(auto_panel)
	# Click tab
	var click_panel = PanelUpgradesScene.instantiate()
	click_panel.upgrade_kind = "click"
	click_panel.name = "Klick"
	_tab_container.add_child(click_panel)
	# Research tab
	var research_panel = PanelResearchScene.instantiate()
	research_panel.name = "Forschung"
	_tab_container.add_child(research_panel)
	# Achievements tab
	var ach_panel = PanelAchievementsScene.instantiate()
	ach_panel.name = "Erfolge"
	_tab_container.add_child(ach_panel)
	# Meta tab
	var meta_panel = PanelMetaScene.instantiate()
	meta_panel.name = "Meta"
	_tab_container.add_child(meta_panel)
	_tab_container.current_tab = 0
