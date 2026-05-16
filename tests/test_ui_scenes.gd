extends SceneTree
##
## Headless test for the Phase-1 greybox UI (P1-011).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_ui_scenes.gd
##
## Visual rendering can't be validated headless (no GPU surface). This suite
## covers everything reachable without a render:
##   - hud.tscn loads + instantiates and HUD labels update on dna_changed
##   - upgrade_card.tscn loads + setup() populates name/cost/count labels
##   - panel_upgrades.tscn (auto) loads and creates 30 cards
##   - panel_upgrades.tscn (click) loads and creates 30 cards
##   - panel_meta.tscn loads and the prestige button starts disabled
##   - panel_research.tscn loads (12 entries)
##   - panel_achievements.tscn loads (27 rows) and reacts to achievement_unlocked
##   - tabs.tscn loads with 5 tabs
##   - main.tscn loads as the root scene with HUD/CellRow/Tabs children
##

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	TickSystem.set_auto_save_enabled(false)
	TickSystem.pause()
	await create_timer(0.05).timeout

	_test_hud_loads_and_updates()
	_test_upgrade_card_setup()
	_test_panel_upgrades_auto()
	_test_panel_upgrades_click()
	_test_panel_meta()
	_test_panel_research()
	_test_panel_achievements_reactivity()
	_test_tabs_has_five_panels()
	_test_main_scene_structure()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_hud_loads_and_updates() -> void:
	var hud = _instantiate("res://scenes/ui/hud.tscn")
	if hud == null:
		_failures.append("hud.tscn failed to instantiate")
		return
	root.add_child(hud)
	await process_frame
	var dna_label: Label = hud.get_node("Margin/HBox/DnaVBox/DnaValue") as Label
	if dna_label == null:
		_failures.append("HUD: DnaValue label missing")
		return
	# Reset state, push DNA, verify HUD updated.
	var before: float = GameState.dna
	GameState.dna = 1234.0
	GameState.dna_changed.emit(GameState.dna, 1234.0)
	await process_frame
	var displayed: String = dna_label.text
	GameState.dna = before
	if displayed.find("1.23K") < 0 and displayed.find("1234") < 0:
		_failures.append("HUD did not show 1234 (got '%s')" % displayed)
		return
	_passes += 1
	hud.queue_free()

func _test_upgrade_card_setup() -> void:
	var card = _instantiate("res://scenes/ui/upgrade_card.tscn")
	if card == null:
		_failures.append("upgrade_card.tscn failed to instantiate")
		return
	root.add_child(card)
	card.setup("auto_001", "auto")
	await process_frame
	var name_label: Label = card.get_node("Margin/VBox/Row/NameVBox/NameLabel") as Label
	if name_label == null:
		_failures.append("UpgradeCard: NameLabel missing")
		return
	if name_label.text.is_empty() or name_label.text == "Upgrade Name":
		_failures.append("UpgradeCard.setup did not populate name (got '%s')" % name_label.text)
		return
	_passes += 1
	card.queue_free()

func _test_panel_upgrades_auto() -> void:
	var panel = _instantiate("res://scenes/ui/panel_upgrades.tscn")
	if panel == null:
		_failures.append("panel_upgrades.tscn failed to instantiate")
		return
	panel.upgrade_kind = "auto"
	root.add_child(panel)
	await process_frame
	var vbox = panel.get_node("VBox")
	if vbox.get_child_count() != 30:
		_failures.append("auto panel: expected 30 cards, got %d" % vbox.get_child_count())
	else:
		_passes += 1
	panel.queue_free()

func _test_panel_upgrades_click() -> void:
	var panel = _instantiate("res://scenes/ui/panel_upgrades.tscn")
	if panel == null:
		_failures.append("panel_upgrades.tscn failed (click variant)")
		return
	panel.upgrade_kind = "click"
	root.add_child(panel)
	await process_frame
	var vbox = panel.get_node("VBox")
	if vbox.get_child_count() != 30:
		_failures.append("click panel: expected 30 cards, got %d" % vbox.get_child_count())
	else:
		_passes += 1
	panel.queue_free()

func _test_panel_meta() -> void:
	var panel = _instantiate("res://scenes/ui/panel_meta.tscn")
	if panel == null:
		_failures.append("panel_meta.tscn failed to instantiate")
		return
	root.add_child(panel)
	await process_frame
	var btn: Button = panel.get_node("VBox/PrestigeGroup/PrestigeVBox/PrestigeButton") as Button
	if btn == null:
		_failures.append("Meta: prestige button missing")
		return
	# Starts disabled (0 EP at 0 lifetime).
	if not btn.disabled:
		_failures.append("Meta: prestige button should start disabled (0 EP)")
		return
	_passes += 1
	panel.queue_free()

func _test_panel_research() -> void:
	var panel = _instantiate("res://scenes/ui/panel_research.tscn")
	if panel == null:
		_failures.append("panel_research.tscn failed to instantiate")
		return
	root.add_child(panel)
	await process_frame
	var vbox = panel.get_node("VBox")
	if vbox.get_child_count() != 12:
		_failures.append("research panel: expected 12 rows, got %d" % vbox.get_child_count())
	else:
		_passes += 1
	panel.queue_free()

func _test_panel_achievements_reactivity() -> void:
	GameState.achievements_unlocked = {}
	var panel = _instantiate("res://scenes/ui/panel_achievements.tscn")
	if panel == null:
		_failures.append("panel_achievements.tscn failed to instantiate")
		return
	root.add_child(panel)
	await process_frame
	var vbox = panel.get_node("VBox")
	if vbox.get_child_count() != 27:
		_failures.append("achievements panel: expected 27 rows, got %d" % vbox.get_child_count())
		panel.queue_free()
		return
	# Emit an unlock and verify the row label updates.
	GameState.achievements_unlocked["achievement_001"] = 1
	GameState.achievement_unlocked.emit("achievement_001")
	await process_frame
	# Find row whose meta tag matches achievement_001
	var unlocked_row: Node = null
	for row in vbox.get_children():
		if (row as Node).get_meta("achievement_id", "") == "achievement_001":
			unlocked_row = row
			break
	if unlocked_row == null:
		_failures.append("achievement_001 row not found")
	elif abs((unlocked_row as CanvasItem).modulate.r - 1.0) > 0.1:
		_failures.append("achievement_001 row did not undim after unlock (got modulate=%s)"
			% str((unlocked_row as CanvasItem).modulate))
	else:
		_passes += 1
	GameState.achievements_unlocked = {}
	panel.queue_free()

func _test_tabs_has_five_panels() -> void:
	var tabs = _instantiate("res://scenes/ui/tabs.tscn")
	if tabs == null:
		_failures.append("tabs.tscn failed to instantiate")
		return
	root.add_child(tabs)
	await process_frame
	var container: TabContainer = tabs.get_node("TabContainer") as TabContainer
	if container.get_tab_count() != 5:
		_failures.append("tabs: expected 5, got %d" % container.get_tab_count())
	else:
		_passes += 1
	tabs.queue_free()

func _test_main_scene_structure() -> void:
	var main = _instantiate("res://scenes/main.tscn")
	if main == null:
		_failures.append("main.tscn failed to instantiate")
		return
	root.add_child(main)
	await process_frame
	# Verify VBox + HUD + CellRow + Tabs children exist.
	if main.get_node_or_null("VBox/HUD") == null:
		_failures.append("main: HUD child missing")
	if main.get_node_or_null("VBox/CellRow") == null:
		_failures.append("main: CellRow child missing")
	if main.get_node_or_null("VBox/Tabs") == null:
		_failures.append("main: Tabs child missing")
	if main.get_node_or_null("VBox/CellRow/ClickArea") == null:
		_failures.append("main: ClickArea (click button) missing")
	if main.get_node_or_null("VBox/CellRow/BioNexus") == null:
		_failures.append("main: BioNexus sub-scene missing")
	# If all checks above passed, count one pass for the full structure.
	if _failures.is_empty() or not _failures[-1].begins_with("main:"):
		_passes += 1
	main.queue_free()

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

func _instantiate(path: String) -> Node:
	if not ResourceLoader.exists(path):
		_failures.append("Scene file missing: %s" % path)
		return null
	var pscene: PackedScene = ResourceLoader.load(path) as PackedScene
	if pscene == null:
		_failures.append("Not a PackedScene: %s" % path)
		return null
	return pscene.instantiate()

func _report() -> void:
	print("")
	print("================================================================")
	print("UI scene tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
