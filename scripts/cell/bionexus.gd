extends MultiMeshInstance3D
##
## BioNexus controller — Phase 1 / P1-010.
##
## Owns the Fibonacci-sphere cluster layout for the cell visual, the
## shader uniform updates (time, morph, swim, click_strength), the
## camera dolly, and the visible_instance_count tweening as the player
## progresses through stages.
##
## Input drivers (read once per frame from autoloads):
##   GameState.stage          → target cluster size + morph + swim
##   ClickSystem.click_landed → shockwave at the click world-pos
##   TickSystem.visual_tick   → drives shader time + animations
##
## The full per-instance layout matches the HTML/Three.js prototype
## (Fibonacci sphere with deterministic jitter, cellType differentiation
## of inner vs outer cells, targetPos for the organism morph).
##

const MAX_INSTANCES: int = 4000

# Stage tuning (per-tier targets — extracted from the prototype's
# stageToTargets() so the look matches across both renderers).
# Each entry: cell-count, morph (0..1), swim (0..1), camera-z.
const STAGE_TARGETS: Array = [
	{"count":    1, "morph": 0.0, "swim": 0.0, "cam_z": 14.0},  # tier 1
	{"count":    8, "morph": 0.0, "swim": 0.0, "cam_z": 18.0},
	{"count":   24, "morph": 0.0, "swim": 0.0, "cam_z": 22.0},
	{"count":   60, "morph": 0.0, "swim": 0.0, "cam_z": 26.0},
	{"count":  120, "morph": 0.0, "swim": 0.0, "cam_z": 30.0},
	{"count":  240, "morph": 0.0, "swim": 0.0, "cam_z": 34.0},
	{"count":  420, "morph": 0.0, "swim": 0.0, "cam_z": 38.0},
	{"count":  700, "morph": 0.0, "swim": 0.0, "cam_z": 42.0},  # tier 8
	{"count": 1100, "morph": 0.0, "swim": 0.0, "cam_z": 46.0},
	{"count": 1600, "morph": 0.0, "swim": 0.0, "cam_z": 50.0},
	{"count": 2100, "morph": 0.1, "swim": 0.0, "cam_z": 54.0},
	{"count": 2500, "morph": 0.3, "swim": 0.0, "cam_z": 56.0},  # tier 12
	{"count": 2800, "morph": 0.5, "swim": 0.0, "cam_z": 58.0},
	{"count": 3000, "morph": 0.7, "swim": 0.2, "cam_z": 60.0},
	{"count": 3200, "morph": 0.85, "swim": 0.4, "cam_z": 62.0},
	{"count": 3400, "morph": 1.0, "swim": 0.5, "cam_z": 64.0},  # tier 16
	{"count": 3500, "morph": 1.0, "swim": 0.6, "cam_z": 64.0},
	{"count": 3600, "morph": 1.0, "swim": 0.7, "cam_z": 64.0},
	{"count": 3700, "morph": 1.0, "swim": 0.8, "cam_z": 64.0},
	{"count": 3800, "morph": 1.0, "swim": 0.9, "cam_z": 64.0},  # tier 20
	{"count": 3850, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 3900, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 3950, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 4000, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 4000, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 4000, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 4000, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 4000, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 4000, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},
	{"count": 4000, "morph": 1.0, "swim": 1.0, "cam_z": 64.0},  # tier 30
]

const ORGANISM_LENGTH: float = 28.0

var _shader_material: ShaderMaterial
var _camera: Camera3D
var _time: float = 0.0
var _click_strength: float = 0.0
var _morph_current: float = 0.0
var _swim_current: float = 0.0
var _cam_z_current: float = 14.0
var _last_stage_applied: int = -1

func _ready() -> void:
	_shader_material = material_override as ShaderMaterial
	# Camera is a sibling of self under the SubViewport.
	_camera = get_node_or_null("../Camera3D") as Camera3D
	_seed_instance_data()
	_layout_cluster(STAGE_TARGETS[0]["count"])
	multimesh.visible_instance_count = STAGE_TARGETS[0]["count"]
	# Wire up upstream signals when autoloads are available.
	if get_node_or_null("/root/TickSystem") != null:
		TickSystem.visual_tick.connect(_on_visual_tick)
	if get_node_or_null("/root/GameState") != null:
		GameState.stage_changed.connect(_on_stage_changed)
	if get_node_or_null("/root/ClickSystem") != null:
		ClickSystem.click_landed.connect(_on_click_landed)
	# Initial alignment with the loaded stage.
	_apply_stage_targets(GameState.stage)

# ----------------------------------------------------------------------------
# Per-instance seed (targetPos, clusterOffset, cellType) — set once per run.
# Mirrors the HTML prototype's generateOrganismShape() so the visual identity
# matches across both renderers.
# ----------------------------------------------------------------------------
func _seed_instance_data() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xB10  # deterministic so each run looks identical
	for i in MAX_INSTANCES:
		# targetPos: distribute along organism length with thickness fall-off
		var t: float = (float(i) + 0.5) / float(MAX_INSTANCES)
		var t_signed: float = (t - 0.5) * 2.0
		t = (sign(t_signed) * pow(abs(t_signed), 0.8) + 1.0) / 2.0
		var x: float = (t - 0.5) * ORGANISM_LENGTH
		var thickness: float = sin(t * PI) * 3.6
		if t > 0.7:
			thickness += sin((t - 0.7) * PI / 0.3) * 1.2
		if t < 0.1:
			thickness *= (t * 10.0)
		var ang: float = rng.randf() * TAU
		var rad: float = rng.randf()
		var is_organ: bool = rad < 0.35 and t > 0.2 and t < 0.85
		var r: float = (rad if is_organ else sqrt(rad)) * thickness
		var target_pos := Vector3(x, sin(ang) * r, cos(ang) * r)
		var cluster_offset: float = rng.randf() * 100.0
		var cell_type: float = 1.0 if is_organ else 0.0
		# COLOR.rgb = targetPos, COLOR.a = cellType
		multimesh.set_instance_color(i, Color(target_pos.x, target_pos.y, target_pos.z, cell_type))
		# INSTANCE_CUSTOM.x = clusterOffset (other channels unused in v1)
		multimesh.set_instance_custom_data(i, Color(cluster_offset, 0.0, 0.0, 0.0))

# ----------------------------------------------------------------------------
# Fibonacci-sphere cluster layout — sets per-instance transform for the
# first `count` instances. Cheap re-run when count changes (every tier).
# ----------------------------------------------------------------------------
func _layout_cluster(count: int) -> void:
	count = clamp(count, 1, MAX_INSTANCES)
	var phi: float = PI * (3.0 - sqrt(5.0))
	var radius: float = (0.0 if count <= 1
		else pow(float(count - 1), 1.0 / 3.0) * 0.95)
	# Cell scale interpolates from 5.0× at count=1 down to 1.0 by count≈250
	# (matches the prototype's "hero cell at low counts" treatment).
	var s_lerp: float = clamp(log(float(max(1, count))) / log(10.0) / 2.4, 0.0, 1.0)
	var cell_scale: float = lerp(5.0, 1.0, s_lerp)
	var t := Transform3D()
	for i in count:
		var y: float = (0.0 if count == 1
			else 1.0 - (float(i) / float(count - 1)) * 2.0)
		var r: float = sqrt(max(0.0, 1.0 - y * y))
		var theta: float = phi * float(i)
		var jitter: float = 1.0 + sin(float(i) * 12.9898) * 0.18
		var pos := Vector3(
			cos(theta) * r * radius * jitter,
			y * radius * jitter,
			sin(theta) * r * radius * jitter,
		)
		t = Transform3D(Basis().scaled(Vector3.ONE * cell_scale), pos)
		multimesh.set_instance_transform(i, t)

# ----------------------------------------------------------------------------
# Signal handlers
# ----------------------------------------------------------------------------

func _on_visual_tick(dt_seconds: float) -> void:
	_time += dt_seconds
	# Smoothly chase the current targets so a stage-up doesn't pop.
	var target := _get_stage_target(GameState.stage)
	var step: float = clamp(dt_seconds * 1.5, 0.0, 1.0)
	_morph_current = lerp(_morph_current, float(target["morph"]), step)
	_swim_current = lerp(_swim_current, float(target["swim"]), step)
	_cam_z_current = lerp(_cam_z_current, float(target["cam_z"]), step)
	# Click impulse decays exponentially.
	_click_strength = max(0.0, _click_strength * exp(-dt_seconds * 4.0))
	# Push uniforms.
	if _shader_material:
		_shader_material.set_shader_parameter("time", _time)
		_shader_material.set_shader_parameter("morph", _morph_current)
		_shader_material.set_shader_parameter("swim", _swim_current)
		_shader_material.set_shader_parameter("click_strength", _click_strength)
	if _camera:
		_camera.position.z = _cam_z_current

func _on_stage_changed(new_stage: int, _old_stage: int) -> void:
	_apply_stage_targets(new_stage)

func _on_click_landed(_amount: float, _pos: Vector2, is_crit: bool, _combo: int) -> void:
	# Trigger a shockwave centred on the cluster (UI converts screen-pos
	# to world later in P1-011; for now we drive from the cluster origin).
	_click_strength = min(1.0, _click_strength + (0.4 if not is_crit else 0.8))
	if _shader_material:
		_shader_material.set_shader_parameter("click_pos", Vector3.ZERO)
		# Slight palette nudge on crit so the flash reads brighter.
		var glow: Color = Color(1.0, 0.36, 0.64) if is_crit else Color(0.31, 0.82, 1.0)
		_shader_material.set_shader_parameter("color_glow", glow)

# ----------------------------------------------------------------------------
# Stage application — recompute visible_instance_count + targets when the
# player stages up. _on_visual_tick handles the lerp toward those targets.
# ----------------------------------------------------------------------------
func _apply_stage_targets(stage: int) -> void:
	if stage == _last_stage_applied:
		return
	_last_stage_applied = stage
	var target := _get_stage_target(stage)
	var count: int = int(target["count"])
	multimesh.visible_instance_count = clamp(count, 1, MAX_INSTANCES)
	# Re-lay the cluster if count changed (cheap; runs once per stage-up).
	_layout_cluster(count)

func _get_stage_target(stage: int) -> Dictionary:
	var idx: int = clamp(stage - 1, 0, STAGE_TARGETS.size() - 1)
	return STAGE_TARGETS[idx]
