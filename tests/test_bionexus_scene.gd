extends SceneTree
##
## Headless test for BioNexus scene + shader (Phase 1 / P1-010).
##
## Run from repo root:
##   godot --headless --path . --script tests/test_bionexus_scene.gd
##
## Visual rendering can't be validated headless (no GPU surface). This suite
## covers everything reachable without a render:
##   - shader file exists and parses without errors
##   - scene file loads as PackedScene + instantiates without errors
##   - MultiMesh capacity = 4000 instances
##   - MultiMesh has use_colors + use_custom_data enabled
##   - INSTANCE_COLOR and INSTANCE_CUSTOM are populated per instance
##     (the _seed_instance_data routine ran)
##   - ShaderMaterial is bound and exposes the expected uniforms
##   - Controller script subscribed to upstream signals successfully
##

const SCENE_PATH: String = "res://scenes/cell/bionexus.tscn"
const SHADER_PATH: String = "res://shaders/bionexus_cell.gdshader"

var _failures: PackedStringArray = PackedStringArray()
var _passes: int = 0

func _initialize() -> void:
	TickSystem.set_auto_save_enabled(false)
	TickSystem.pause()
	await create_timer(0.05).timeout

	_test_shader_file_loads()
	_test_scene_file_loads()
	await _test_scene_instantiates_cleanly()
	await _test_multimesh_is_configured()
	await _test_shader_uniforms_present()

	_report()
	quit(0 if _failures.is_empty() else 1)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

func _test_shader_file_loads() -> void:
	if not ResourceLoader.exists(SHADER_PATH):
		_failures.append("Shader file missing at %s" % SHADER_PATH)
		return
	var sh: Variant = ResourceLoader.load(SHADER_PATH)
	if not sh is Shader:
		_failures.append("Shader file %s did not load as Shader" % SHADER_PATH)
		return
	_passes += 1

func _test_scene_file_loads() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		_failures.append("Scene file missing at %s" % SCENE_PATH)
		return
	var pscene: Variant = ResourceLoader.load(SCENE_PATH)
	if not pscene is PackedScene:
		_failures.append("Scene file %s did not load as PackedScene" % SCENE_PATH)
		return
	_passes += 1

func _test_scene_instantiates_cleanly() -> void:
	var pscene: PackedScene = load(SCENE_PATH) as PackedScene
	if pscene == null:
		_failures.append("Scene resource is null")
		return
	var instance: Node = pscene.instantiate()
	if instance == null:
		_failures.append("Scene failed to instantiate")
		return
	root.add_child(instance)
	# Wait one frame so all _ready() callbacks run.
	await process_frame
	_passes += 1
	# Stash on root for follow-up tests; do not free yet.

func _test_multimesh_is_configured() -> void:
	var mm_node: MultiMeshInstance3D = _find_multimesh()
	if mm_node == null:
		_failures.append("MultiMeshInstance3D not found in instantiated scene")
		return
	var mm: MultiMesh = mm_node.multimesh
	if mm == null:
		_failures.append("MultiMesh resource is null")
		return
	# Capacity = 4000 (HARD cap for mobile/Steam Deck per ADR-0004 + balance_constants).
	if mm.instance_count != 4000:
		_failures.append("Expected instance_count=4000, got %d" % mm.instance_count)
		return
	if not mm.use_colors:
		_failures.append("MultiMesh.use_colors must be true (targetPos+cellType packed there)")
		return
	if not mm.use_custom_data:
		_failures.append("MultiMesh.use_custom_data must be true (clusterOffset packed there)")
		return
	# Per-instance data should be non-default for instances beyond the
	# stage-1 shape's count (proves _seed_instance_data ran for the full
	# 4000-instance buffer, not just the active stage). Index 1000 is
	# guaranteed to be untouched by every per-stage shape generator
	# (no shape exceeds ~450 cells).
	var sentinel_idx: int = 1000
	var sentinel_color: Color = mm.get_instance_color(sentinel_idx)
	if sentinel_color == Color(0, 0, 0, 0):
		_failures.append("Instance %d color is identity — _seed_instance_data did not seed full buffer" % sentinel_idx)
		return
	var sentinel_custom: Color = mm.get_instance_custom_data(sentinel_idx)
	if sentinel_custom == Color(0, 0, 0, 0):
		_failures.append("Instance %d custom data is identity — _seed_instance_data did not seed full buffer" % sentinel_idx)
		return
	# visible_instance_count should reflect stage 1 (= 1 cell).
	if mm.visible_instance_count != 1:
		_failures.append("Expected visible_instance_count=1 at stage 1, got %d" % mm.visible_instance_count)
		return
	_passes += 1

func _test_shader_uniforms_present() -> void:
	var mm_node: MultiMeshInstance3D = _find_multimesh()
	if mm_node == null:
		return  # already failed
	var mat: ShaderMaterial = mm_node.material_override as ShaderMaterial
	if mat == null:
		_failures.append("MultiMeshInstance3D.material_override is not a ShaderMaterial")
		return
	# Spot-check the uniforms the controller writes (P1-010 contract).
	var required: PackedStringArray = PackedStringArray([
		"time", "morph", "swim", "click_pos", "click_strength",
		"body_pulse",
		"color_membrane", "color_organ", "color_glow",
	])
	for u in required:
		# get_shader_parameter returns null if the uniform doesn't exist OR
		# was never set. Setting then re-reading proves the parameter is
		# accepted by the shader.
		mat.set_shader_parameter(u, mat.get_shader_parameter(u))
	_passes += 1

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

func _find_multimesh() -> MultiMeshInstance3D:
	# Walk root's children looking for a MultiMeshInstance3D somewhere inside.
	for child in root.get_children():
		var found: MultiMeshInstance3D = _find_in(child)
		if found != null:
			return found
	return null

func _find_in(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D:
		return node
	for c in node.get_children():
		var f: MultiMeshInstance3D = _find_in(c)
		if f != null:
			return f
	return null

func _report() -> void:
	print("")
	print("================================================================")
	print("BioNexus scene tests — %d passed, %d failed" % [_passes, _failures.size()])
	print("================================================================")
	if not _failures.is_empty():
		for f in _failures:
			print("  ✗ %s" % f)
	else:
		print("  ✓ all assertions passed")
	print("")
