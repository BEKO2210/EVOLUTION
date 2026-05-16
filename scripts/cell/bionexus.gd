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

# Stage tuning (per-tier targets — counts and camera distances for stages 1-9
# bumped so the dedicated silhouettes (proto / rna / dna / capsid / rod /
# rod+flagellum / lumpy / amoeba / ellipsoid) read clearly at the closer
# camera. morph=1.0 for stages 2-9 so the shader uses the per-shape target
# positions instead of the cluster transform.
# Each entry: cell-count, morph (0..1), swim (0..1), camera-z.
const STAGE_TARGETS: Array = [
	{"count":    1, "morph": 0.0, "swim": 0.0, "cam_z": 14.0},  # tier 1 — proto (hero blob, no morph needed)
	{"count":  120, "morph": 1.0, "swim": 0.0, "cam_z": 16.0},  # tier 2 — rna strand
	{"count":  200, "morph": 1.0, "swim": 0.0, "cam_z": 18.0},  # tier 3 — dna helix
	{"count":  220, "morph": 1.0, "swim": 0.0, "cam_z": 14.0},  # tier 4 — virus capsid
	{"count":  260, "morph": 1.0, "swim": 0.0, "cam_z": 12.0},  # tier 5 — prokaryot rod
	{"count":  320, "morph": 1.0, "swim": 0.0, "cam_z": 18.0},  # tier 6 — bakterium + flagellum
	{"count":  350, "morph": 1.0, "swim": 0.0, "cam_z": 14.0},  # tier 7 — archaea lumpy
	{"count":  400, "morph": 1.0, "swim": 0.0, "cam_z": 16.0},  # tier 8 — amoeba + arms
	{"count":  450, "morph": 1.0, "swim": 0.0, "cam_z": 22.0},  # tier 9 — paramecium ellipsoid
	{"count": 1600, "morph": 0.0, "swim": 0.0, "cam_z": 50.0},  # tier 10 — back to cluster aesthetic
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

# Default palette — used until the first stage_visual is applied (and as a
# fallback when DataLoader is unavailable, e.g. in the smoke test scene).
const DEFAULT_MEMBRANE := Color(0.0, 1.0, 0.64)
const DEFAULT_ORGAN    := Color(1.0, 0.82, 0.29)
const DEFAULT_GLOW     := Color(0.31, 0.82, 1.0)

var _shader_material: ShaderMaterial
var _camera: Camera3D
var _time: float = 0.0
var _click_strength: float = 0.0
var _morph_current: float = 0.0
var _swim_current: float = 0.0
var _cam_z_current: float = 14.0
var _last_stage_applied: int = -1

# Per-stage palette targets — set in _apply_stage_visuals, lerped toward in
# _on_visual_tick. Mirrors the HTML prototype (PR #30 / commit d244083).
var _target_membrane: Color = DEFAULT_MEMBRANE
var _target_organ:    Color = DEFAULT_ORGAN
var _target_glow:     Color = DEFAULT_GLOW
var _current_membrane: Color = DEFAULT_MEMBRANE
var _current_organ:    Color = DEFAULT_ORGAN
var _current_glow:     Color = DEFAULT_GLOW

# Per-stage rotation rate (rad/s on each axis), applied per visual frame.
var _rotation_rate: Vector3 = Vector3.ZERO
var _rotation_accum: Vector3 = Vector3.ZERO

# Active signature kind ("plasma", "breathe", "swim", "glide", ...). Empty
# string = no signature, body_pulse stays at zero.
var _signature: String = ""

# Signature-driven cluster offset (e.g. paramecium glide, bacterium kick).
var _signature_offset: Vector3 = Vector3.ZERO
var _current_offset: Vector3 = Vector3.ZERO

# Current body_pulse value (0..1), lerped each frame toward the per-signature
# target computed in _compute_pulse_target.
var _body_pulse: float = 0.0

# Most recent swim phase computed during _compute_pulse_target — exposed so
# the bacterium signature can use the same wave for both pulse + offset.
var _swim_phase: float = 0.0

# Active per-stage silhouette ("fibonacci", "rna", "dna", ...). Used to
# dispatch per-frame shape animations (tail wave, pseudopod wiggle).
var _active_shape_kind: String = ""

# Bakterium flagellum metadata, set by _shape_rod_flagellum. The animator
# reads these to overwrite the tail instances each frame with a traveling
# sine wave (HTML reference: animateBakteriumTail).
var _tail_start_idx: int = 0
var _tail_count_anim: int = 0
var _tail_start_x: float = 0.0

# Amoeba pseudopod metadata, set by _shape_amoeba. The animator wiggles
# each arm independently with its own phase + extension cycle (HTML
# reference: animateAmoebaPseudopods).
var _arm_start_idx: int = 0
var _arms_n: int = 0
var _cells_per_arm: int = 0
var _arm_remainder: int = 0
var _amoeba_core_r: float = 0.0

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
# Per-stage silhouette generators — port of the HTML shapeXxx() functions
# (index.html rev d244083). Each writes target positions for the first
# `count` instances directly into INSTANCE_COLOR (rgb = target_pos, a = cell
# type). cellType policy mirrors the HTML applyShape() per-shape rules:
#   dna     -> halfStrand A=0/membrane, halfStrand B=1/organ, rungs alternate
#   capsid  -> capsid cells 0/membrane, spike cells 1/organ
#   others  -> uniform 0/membrane
# Called from _apply_stage_shape on stage change, cheap (one-shot per tier).
# ----------------------------------------------------------------------------

# Reseeds the organism-shape target positions written by _seed_instance_data.
# Used when the active stage is "fibonacci" (cluster aesthetic). Identical
# math to _seed_instance_data so a stage 9 -> 10 transition produces the same
# late-game organism layout the player saw the first time around.
func _reseed_organism_shape(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xB10
	for i in count:
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
		var cell_type: float = 1.0 if is_organ else 0.0
		multimesh.set_instance_color(i, Color(x, sin(ang) * r, cos(ang) * r, cell_type))

func _shape_proto(count: int) -> void:
	# Single hero blob at origin — morph has no effect.
	for i in count:
		multimesh.set_instance_color(i, Color(0.0, 0.0, 0.0, 0.0))

func _shape_rna(count: int) -> void:
	# Single right-handed helix (RNA strand). Wider than real RNA so it
	# reads as a spiral at the game's camera distance.
	var turns: float = 4.5
	var length: float = 14.0
	var radius: float = 3.0
	for i in count:
		var t: float = float(i) / float(max(1, count - 1))
		var a: float = t * turns * TAU
		multimesh.set_instance_color(i, Color(
			cos(a) * radius, (t - 0.5) * length, sin(a) * radius, 0.0))

func _shape_dna(count: int) -> void:
	# Two intertwined right-handed strands + base-pair rungs between them.
	var turns: float = 3.0
	var length: float = 20.0
	var radius: float = 5.0
	var strand_frac: float = 0.36
	var half_strand: int = max(1, int(float(count) * strand_frac))
	var rung_count: int = max(0, count - 2 * half_strand)
	for i in half_strand:
		var t: float = float(i) / float(max(1, half_strand - 1))
		var a: float = t * turns * TAU
		var y: float = (t - 0.5) * length
		# Strand A — cellType 0 (membrane / first colour)
		multimesh.set_instance_color(i, Color(cos(a) * radius, y, sin(a) * radius, 0.0))
		# Strand B — π-offset, cellType 1 (organ / second colour)
		var j: int = i + half_strand
		multimesh.set_instance_color(j, Color(cos(a + PI) * radius, y, sin(a + PI) * radius, 1.0))
	# Rungs span the two strands at fractional positions; alternate cellType.
	var seg_count: int = max(1, int(ceil(float(rung_count) / 4.0)))
	for i in rung_count:
		var seg_idx: int = i / 4
		var seg_pos: float = float(i % 4) / 4.0
		var tt: float = (float(seg_idx) + 0.5) / float(seg_count)
		var a: float = tt * turns * TAU
		var y: float = (tt - 0.5) * length
		var xa: float = cos(a) * radius
		var za: float = sin(a) * radius
		var xb: float = cos(a + PI) * radius
		var zb: float = sin(a + PI) * radius
		var k: int = 2 * half_strand + i
		var ct: float = float(i & 1)
		multimesh.set_instance_color(k, Color(
			xa + (xb - xa) * seg_pos, y, za + (zb - za) * seg_pos, ct))

func _shape_capsid(count: int) -> void:
	# Icosahedral capsid (Fibonacci sphere) + protruding spike layer for
	# the classic virus silhouette.
	var capsid_count: int = max(1, int(float(count) * 0.75))
	var spike_count: int = max(0, count - capsid_count)
	var r: float = 4.4
	var phi: float = PI * (3.0 - sqrt(5.0))
	for i in capsid_count:
		var y: float = (0.0 if capsid_count <= 1
			else 1.0 - (float(i) / float(capsid_count - 1)) * 2.0)
		var cr: float = sqrt(max(0.0, 1.0 - y * y))
		var th: float = phi * float(i)
		multimesh.set_instance_color(i, Color(
			cos(th) * cr * r, y * r, sin(th) * cr * r, 0.0))
	var spike_r: float = r * 1.55
	for i in spike_count:
		var y: float = (0.0 if spike_count <= 1
			else 1.0 - (float(i) / float(spike_count - 1)) * 2.0)
		var cr: float = sqrt(max(0.0, 1.0 - y * y))
		var th: float = phi * float(i) + 0.6
		var k: int = capsid_count + i
		multimesh.set_instance_color(k, Color(
			cos(th) * cr * spike_r, y * spike_r, sin(th) * cr * spike_r, 1.0))

func _shape_rod(count: int) -> void:
	# Small densely-packed coccus (prokaryot) — uniform Fibonacci sphere.
	var r: float = 2.8
	var phi: float = PI * (3.0 - sqrt(5.0))
	for i in count:
		var y: float = (0.0 if count <= 1
			else 1.0 - (float(i) / float(count - 1)) * 2.0)
		var cr: float = sqrt(max(0.0, 1.0 - y * y))
		var th: float = phi * float(i)
		multimesh.set_instance_color(i, Color(
			cos(th) * cr * r, y * r, sin(th) * cr * r, 0.0))

func _shape_rod_flagellum(count: int) -> void:
	# Bacillus capsule + static flagellum tail seed. Tail animation lives
	# in a follow-up — here we just lay down the silhouette.
	var tail_frac: float = 0.22
	var tail_count: int = max(8, int(float(count) * tail_frac))
	var body_count: int = count - tail_count
	var body_len: float = 7.5
	var body_r: float = 1.9
	var phi: float = PI * (3.0 - sqrt(5.0))
	for i in body_count:
		var u: float = (0.5 if body_count <= 1
			else float(i) / float(body_count - 1))
		var ang: float = phi * float(i)
		var x: float
		var r: float
		if u < 0.18:
			# -X hemispherical cap
			var v: float = u / 0.18
			var theta: float = v * PI * 0.5
			x = -body_len * 0.5 - cos(theta) * body_r + body_r
			r = sin(theta) * body_r
		elif u > 0.82:
			# +X hemispherical cap (flagellum attaches here)
			var v: float = (u - 0.82) / 0.18
			var theta: float = v * PI * 0.5
			x = body_len * 0.5 + sin(theta) * body_r
			r = cos(theta) * body_r
		else:
			# Cylindrical belt
			var v: float = (u - 0.18) / 0.64
			x = -body_len * 0.5 + body_r + v * body_len
			r = body_r
		multimesh.set_instance_color(i, Color(x, sin(ang) * r, cos(ang) * r, 0.0))
	# Tail seed — straight line trailing the body. _animate_tail rewrites
	# these per frame when the active shape is rod_flagellum.
	var tail_start_x: float = body_len * 0.5 + body_r
	for i in tail_count:
		var t: float = float(i) / float(max(1, tail_count - 1))
		multimesh.set_instance_color(body_count + i,
			Color(tail_start_x + t * 8.0, 0.0, 0.0, 1.0))
	# Stash metadata for the per-frame animator.
	_tail_start_idx = body_count
	_tail_count_anim = tail_count
	_tail_start_x = tail_start_x

func _shape_lumpy(count: int) -> void:
	# Archaea — bumpy spheroid. Fibonacci sphere displaced by deterministic
	# index noise so the silhouette reads as alien-rock.
	var r: float = 3.4
	var phi: float = PI * (3.0 - sqrt(5.0))
	for i in count:
		var y: float = (0.0 if count <= 1
			else 1.0 - (float(i) / float(count - 1)) * 2.0)
		var cr: float = sqrt(max(0.0, 1.0 - y * y))
		var th: float = phi * float(i)
		# Stable per-index hash (matches HTML's sin*43758 trick).
		var n: float = sin(float(i) * 12.9898) * 43758.5453
		var bump: float = 1.0 + ((n - floor(n)) - 0.5) * 0.7
		multimesh.set_instance_color(i, Color(
			cos(th) * cr * r * bump,
			y * r * bump,
			sin(th) * cr * r * bump, 0.0))

func _shape_amoeba(count: int) -> void:
	# Core blob + 4 procedural pseudopod arm seeds (static; wiggle animation
	# lives in a follow-up PR).
	var core_frac: float = 0.6
	var core_count: int = int(float(count) * core_frac)
	var arm_count: int = count - core_count
	var arms: int = 4
	var cells_per_arm: int = int(float(arm_count) / float(arms))
	var arm_remainder: int = arm_count - cells_per_arm * arms
	var r: float = 3.2
	var phi: float = PI * (3.0 - sqrt(5.0))
	for i in core_count:
		var y: float = (0.0 if core_count <= 1
			else 1.0 - (float(i) / float(core_count - 1)) * 2.0)
		var cr: float = sqrt(max(0.0, 1.0 - y * y))
		var th: float = phi * float(i)
		var n: float = (sin(float(i) * 7.13) * 0.5 + 0.5) * 0.25 + 0.95
		multimesh.set_instance_color(i, Color(
			cos(th) * cr * r * n, y * r * n, sin(th) * cr * r * n, 0.0))
	var write_idx: int = core_count
	for a in arms:
		var arm_base_ang: float = float(a) / float(arms) * TAU
		var n_per: int = cells_per_arm + (1 if a < arm_remainder else 0)
		for k in n_per:
			var t: float = float(k + 1) / float(n_per)
			var reach: float = r + t * 4.0
			multimesh.set_instance_color(write_idx, Color(
				cos(arm_base_ang) * reach, 0.0, sin(arm_base_ang) * reach, 0.0))
			write_idx += 1
	# Stash metadata for the per-frame animator (pseudopod wiggle).
	_arm_start_idx = core_count
	_arms_n = arms
	_cells_per_arm = cells_per_arm
	_arm_remainder = arm_remainder
	_amoeba_core_r = r

func _shape_ellipsoid(count: int) -> void:
	# Paramecium — prolate spheroid (elongated oval). Cilia overlay is a
	# 2D UI concern (Phase-2 P2-002 polish ticket).
	var len_x: float = 9.5
	var rad_y: float = 3.0
	var rad_z: float = 3.0
	var phi: float = PI * (3.0 - sqrt(5.0))
	for i in count:
		var y: float = (0.0 if count <= 1
			else 1.0 - (float(i) / float(count - 1)) * 2.0)
		var cr: float = sqrt(max(0.0, 1.0 - y * y))
		var th: float = phi * float(i)
		multimesh.set_instance_color(i, Color(
			cos(th) * cr * len_x, y * rad_y, sin(th) * cr * rad_z, 0.0))

# Dispatches to the per-shape generator. Called on stage transition AFTER
# _layout_cluster has set per-instance transforms for the new count.
func _apply_stage_shape(kind: String, count: int) -> void:
	count = clamp(count, 1, MAX_INSTANCES)
	match kind:
		"proto":         _shape_proto(count)
		"rna":           _shape_rna(count)
		"dna":           _shape_dna(count)
		"capsid":        _shape_capsid(count)
		"rod":           _shape_rod(count)
		"rod_flagellum": _shape_rod_flagellum(count)
		"lumpy":         _shape_lumpy(count)
		"amoeba":        _shape_amoeba(count)
		"ellipsoid":     _shape_ellipsoid(count)
		_:               _reseed_organism_shape(count)  # "fibonacci" / unknown

# ----------------------------------------------------------------------------
# Per-frame shape animations — only run when the active stage has an animated
# silhouette. Cheap (50-200 set_instance_color calls per frame). Each animator
# rewrites a sub-range of INSTANCE_COLOR; the rest of the silhouette stays
# static. Ports of animateBakteriumTail / animateAmoebaPseudopods from HTML
# rev d244083.
# ----------------------------------------------------------------------------
func _animate_active_shape(t: float) -> void:
	match _active_shape_kind:
		"rod_flagellum":
			_animate_tail(t)
		"amoeba":
			_animate_pseudopods(t)

func _animate_tail(t: float) -> void:
	# Sine wave traveling along the tail; amplitude grows toward the tip.
	for i in _tail_count_anim:
		var frac: float = float(i) / float(max(1, _tail_count_anim - 1))
		var x: float = _tail_start_x + frac * 8.0
		var phase: float = frac * 6.5 - t * 6.0
		var amp: float = 0.3 + frac * 1.4
		multimesh.set_instance_color(_tail_start_idx + i, Color(
			x, sin(phase) * amp, cos(phase * 0.5) * amp * 0.25, 1.0))

func _animate_pseudopods(t: float) -> void:
	# Each arm has its own base-angle wobble + extension cycle, plus per-cell
	# lateral wave so the limb feels like it's choosing direction.
	var idx: int = _arm_start_idx
	for a in _arms_n:
		var base_ang: float = float(a) / float(_arms_n) * TAU + sin(t * 0.4 + float(a)) * 0.25
		var extend: float = 0.55 + 0.45 * sin(t * 0.6 + float(a) * 1.7)
		var n_per: int = _cells_per_arm + (1 if a < _arm_remainder else 0)
		var dir_x: float = cos(base_ang)
		var dir_z: float = sin(base_ang)
		var perp_x: float = -dir_z
		var perp_z: float = dir_x
		for k in n_per:
			var ft: float = float(k + 1) / float(max(1, n_per))
			var lateral: float = sin(t * 1.5 + float(a) * 2.0 + ft * 4.0) * 0.4 * ft
			var reach: float = _amoeba_core_r + ft * (3.5 + extend * 2.5)
			multimesh.set_instance_color(idx, Color(
				dir_x * reach + perp_x * lateral,
				sin(t * 1.2 + float(a) + ft * 2.0) * 0.5 * ft,
				dir_z * reach + perp_z * lateral, 0.0))
			idx += 1

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

	# Per-stage signature heartbeat. Computes a 0..1 pulse target for the
	# active signature animation and writes _signature_offset for animations
	# that drift the whole cluster (swim / glide).
	var pulse_target: float = _compute_pulse_target(_time)
	var pulse_step: float = clamp(dt_seconds * 6.0, 0.0, 1.0)
	_body_pulse = lerp(_body_pulse, pulse_target, pulse_step)

	# Per-frame shape animations (tail wave / pseudopod wiggle). Cheap no-op
	# for shapes that don't have animated parts.
	_animate_active_shape(_time)

	# Smooth palette lerp toward the per-stage target — ~1 sec transitions.
	var pal_step: float = clamp(dt_seconds * 1.5, 0.0, 1.0)
	_current_membrane = _current_membrane.lerp(_target_membrane, pal_step)
	_current_organ    = _current_organ.lerp(_target_organ, pal_step)
	_current_glow     = _current_glow.lerp(_target_glow, pal_step)

	# Drift cluster toward signature offset (used by swim / glide).
	var off_step: float = clamp(dt_seconds * 4.0, 0.0, 1.0)
	_current_offset = _current_offset.lerp(_signature_offset, off_step)
	position = _current_offset

	# Apply per-stage rotation (cheap — single rotate per axis).
	_rotation_accum += _rotation_rate * dt_seconds
	rotation = _rotation_accum

	# Push uniforms.
	if _shader_material:
		_shader_material.set_shader_parameter("time", _time)
		_shader_material.set_shader_parameter("morph", _morph_current)
		_shader_material.set_shader_parameter("swim", _swim_current)
		_shader_material.set_shader_parameter("click_strength", _click_strength)
		_shader_material.set_shader_parameter("body_pulse", _body_pulse)
		_shader_material.set_shader_parameter("color_membrane", _current_membrane)
		_shader_material.set_shader_parameter("color_organ", _current_organ)
		# Only push glow when no click is active — _on_click_landed overrides
		# it with crit-pink for the duration of the shockwave decay.
		if _click_strength <= 0.01:
			_shader_material.set_shader_parameter("color_glow", _current_glow)
	if _camera:
		_camera.position.z = _cam_z_current

# ----------------------------------------------------------------------------
# Per-stage signature animation (mirrors HTML prototype rev d244083).
# Returns 0..1 pulse target; writes _signature_offset as a side effect.
# ----------------------------------------------------------------------------
func _compute_pulse_target(t: float) -> float:
	_signature_offset = Vector3.ZERO
	match _signature:
		"plasma":
			# Primordial energy core — sharp-attack solar pulse.
			var phase: float = t * 1.6
			return pow(max(0.0, sin(phase)), 2.2)
		"flow":
			# Calm ride-along pulse on top of rotation.
			return 0.18 + 0.12 * sin(t * 1.1)
		"basepair":
			# DNA ladder double-beat (sin² rhythm).
			var a: float = sin(t * 1.8)
			var b: float = sin(t * 1.8 + PI * 0.5)
			return 0.5 * (a * a + b * b)
		"throb":
			# Ominous slow virus throb.
			return (0.5 + 0.5 * sin(t * 0.9)) * 0.6
		"breathe":
			# Calm breathing cycle.
			return 0.5 + 0.5 * sin(t * 0.7)
		"swim":
			# Bacterium kick — pulse on downstroke, body counter-drifts.
			_swim_phase = sin(t * 6.0)
			_signature_offset.x = -_swim_phase * 0.5
			return 0.4 * max(0.0, -_swim_phase)
		"tumble":
			# Rotation is the show; pulse stays silent.
			return 0.0
		"hunt":
			# Amöbe gulp — pulse synced to slow pseudopod cycle.
			return 0.3 * (0.5 + 0.5 * sin(t * 0.6 + 1.5))
		"glide":
			# Paramecium slow forward drift.
			_signature_offset.x = sin(t * 0.6) * 1.5
			_signature_offset.y = sin(t * 0.4) * 0.3
			return 0.0
		"shimmer":
			# Multiverse iridescence — rapid low-amplitude flicker.
			return 0.25 + 0.20 * sin(t * 3.7) * sin(t * 2.3)
		_:
			return 0.0

func _on_stage_changed(new_stage: int, _old_stage: int) -> void:
	_apply_stage_targets(new_stage)

func _on_click_landed(_amount: float, _pos: Vector2, is_crit: bool, _combo: int) -> void:
	# Trigger a shockwave centred on the cluster (UI converts screen-pos
	# to world later in P1-011; for now we drive from the cluster origin).
	_click_strength = min(1.0, _click_strength + (0.4 if not is_crit else 0.8))
	if _shader_material:
		_shader_material.set_shader_parameter("click_pos", Vector3.ZERO)
		# Crit forces the shockwave halo to pink for instant readability,
		# regardless of the active stage palette. Non-crit uses the per-stage
		# glow colour so the halo stays on-brand for the current creature.
		var glow: Color = Color(1.0, 0.36, 0.64) if is_crit else _current_glow
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
	# Re-lay the cluster (used as the morph=0 endpoint). For stages with a
	# dedicated silhouette (morph=1) the cluster transforms become invisible
	# but we still set them so the shader's MODEL_MATRIX math is well-formed.
	_layout_cluster(count)
	# Per-stage palette + rotation + signature + silhouette — read from
	# DataLoader if the autoload is available (smoke-tests run without it).
	_apply_stage_visuals(stage)

# Pulls the per-stage visual entry (palette/rotation/signature) and updates
# the lerp targets so _on_visual_tick can ease the live uniforms there.
# Falls back to the default palette + no-rotation when DataLoader is not
# available (e.g. dev/smoke-test scenes).
func _apply_stage_visuals(stage: int) -> void:
	var loader: Node = get_node_or_null("/root/DataLoader")
	if loader == null or not loader.is_loaded:
		return
	var visual: Variant = loader.get_stage_visual_by_tier(stage)
	if visual == null:
		# Cross-table validation should make this unreachable, but the
		# renderer must not crash if it ever happens (e.g. data hot-reload
		# mid-game).
		push_warning("[BioNexus] stage %d has no stage_visual entry — keeping previous palette" % stage)
		return
	_target_membrane = Color(String(visual["color_membrane"]))
	_target_organ    = Color(String(visual["color_organ"]))
	_target_glow     = Color(String(visual["color_glow"]))
	_rotation_rate = Vector3(
		float(visual["rotation_x"]),
		float(visual["rotation_y"]),
		float(visual["rotation_z"]),
	)
	var sig: String = String(visual["signature"])
	if _signature != sig:
		# Reset pulse + cluster offset on signature change so a stage-up
		# doesn't carry the previous animation's residual values into the
		# new look.
		_signature = sig
		_body_pulse = 0.0
		_signature_offset = Vector3.ZERO
	# Per-stage silhouette dispatch — re-writes INSTANCE_COLOR target_pos
	# for the first `count` cells. Always re-runs: cheap (a few hundred
	# Color writes), and a count change within the same shape still needs
	# the new positions to fill the now-visible instances.
	var kind: String = String(visual["shape_kind"])
	var count: int = int(_get_stage_target(stage)["count"])
	_active_shape_kind = kind
	_apply_stage_shape(kind, count)

func _get_stage_target(stage: int) -> Dictionary:
	var idx: int = clamp(stage - 1, 0, STAGE_TARGETS.size() - 1)
	return STAGE_TARGETS[idx]
