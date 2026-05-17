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
	{"count":  240, "morph": 1.0, "swim": 0.0, "cam_z": 18.0},  # tier 10 — plant tissue (hex grid)
	{"count":  300, "morph": 1.0, "swim": 0.0, "cam_z": 18.0},  # tier 11 — sponge (porous sphere)
	{"count":  280, "morph": 1.0, "swim": 0.0, "cam_z": 20.0},  # tier 12 — hydra (body + tentacles)
	{"count":  300, "morph": 1.0, "swim": 0.0, "cam_z": 22.0},  # tier 13 — flatworm ribbon
	{"count":  280, "morph": 1.0, "swim": 0.0, "cam_z": 20.0},  # tier 14 — insect (body + legs)
	{"count":  340, "morph": 1.0, "swim": 0.0, "cam_z": 22.0},  # tier 15 — fish (body + fins)
	{"count": 3400, "morph": 1.0, "swim": 0.5, "cam_z": 64.0},  # tier 16 — cluster ramp resumes
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

# Hydra tentacle metadata, set by _shape_hydra. Per-frame animator waves
# each tentacle with its own phase (HTML reference: animateHydraTentacles).
var _hydra_tent_start: int = 0
var _hydra_tents: int = 0
var _hydra_per_tent: int = 0
var _hydra_extra: int = 0
var _hydra_body_len: float = 0.0
var _hydra_body_r: float = 0.0

# Flatworm metadata, set by _shape_worm. Animator displaces the whole body
# along Y with a travelling sine wave (slither).
var _worm_count: int = 0
var _worm_length: float = 0.0
var _worm_half_w: float = 0.0

# Fish metadata, set by _shape_fish. Animator sweeps the caudal-fin cells
# left/right for the tail-beat (body cells stay put).
var _fish_tail_start: int = 0
var _fish_tail_count: int = 0
var _fish_body_len: float = 0.0

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

func _shape_plant(count: int) -> void:
	# Pflanzenzelle — hexagonal-grid tissue with chloroplast-style organ
	# cells sprinkled inside. cellType=1 for ~1-in-5 cells via deterministic
	# sin*cos hash (matches HTML's uniform:'plant' policy).
	var cols: int = 11
	var rows: int = 9
	var spacing: float = 1.55
	var dx: float = spacing
	var dy: float = spacing * sqrt(3.0) * 0.5
	var i: int = 0
	for r in rows:
		if i >= count:
			break
		var y_pos: float = (float(r) - float(rows - 1) * 0.5) * dy
		var x_offset: float = (dx * 0.5 if (r % 2) == 1 else 0.0)
		# Trim row width so the grid reads roughly hexagonal, not boxy.
		var trim: int = (1 if abs(float(r) - float(rows - 1) * 0.5) >= 3.0 else 0)
		var c: int = trim
		while c < cols - trim and i < count:
			var x_pos: float = (float(c) - float(cols - 1) * 0.5) * dx + x_offset
			var jx: float = sin(float(i) * 12.9898) * 0.12
			var jy: float = cos(float(i) * 78.233) * 0.12
			var jz: float = sin(float(i) * 39.346) * 0.6
			# Chloroplast pattern — same hash as HTML so the tissue motif matches.
			var hash: float = sin(float(i) * 9.371) * cos(float(i) * 4.123)
			var ct: float = 1.0 if hash > 0.35 else 0.0
			multimesh.set_instance_color(i, Color(x_pos + jx, y_pos + jy, jz, ct))
			i += 1
			c += 1
	# Any leftover instances: pack as inner cells with a deterministic
	# scatter (no RandomNumberGenerator — keeps the tissue stable across
	# runs unlike the HTML which uses Math.random for the fallback).
	while i < count:
		var a: float = float(i) * 2.39996323
		var rad: float = (float(i % 7) + 1.0) * 0.6
		var hash: float = sin(float(i) * 9.371) * cos(float(i) * 4.123)
		var ct: float = 1.0 if hash > 0.35 else 0.0
		multimesh.set_instance_color(i, Color(
			cos(a) * rad, sin(a) * rad,
			sin(float(i) * 39.346) * 0.6, ct))
		i += 1

func _shape_sponge(count: int) -> void:
	# Schwamm — porous Fibonacci sphere. Cells where the deterministic noise
	# exceeds the threshold are skipped (those gaps become the oscula). The
	# noise is stable per-index so the same holes appear every re-apply.
	var r: float = 4.5
	var phi: float = PI * (3.0 - sqrt(5.0))
	var i: int = 0
	var idx: int = 0
	var attempts: int = 0
	var modulus: int = count + 64
	while i < count and attempts < count * 4:
		var y: float = 1.0 - (float(idx % modulus) / float(modulus)) * 2.0
		var cr: float = sqrt(max(0.0, 1.0 - y * y))
		var th: float = phi * float(idx)
		idx += 1
		attempts += 1
		var n: float = sin(float(idx) * 3.13) * 0.5 + sin(float(idx) * 7.7) * 0.5
		if n > 0.55:
			continue  # pore — skip
		multimesh.set_instance_color(i, Color(
			cos(th) * cr * r, y * r, sin(th) * cr * r, 0.0))
		i += 1
	# If we exhausted attempts before filling, collapse the rest at origin.
	while i < count:
		multimesh.set_instance_color(i, Color(0.0, 0.0, 0.0, 0.0))
		i += 1

func _shape_hydra(count: int) -> void:
	# Hydra — tubular body (cylinder) + 6 radial tentacles from the top.
	# Tentacles get rewritten per frame by _animate_hydra_tentacles.
	var tents: int = 6
	var body_frac: float = 0.55
	var body_count: int = int(float(count) * body_frac)
	var tent_count: int = count - body_count
	var per_tent: int = int(float(tent_count) / float(tents))
	var extra: int = tent_count - per_tent * tents
	var body_len: float = 8.0
	var body_r: float = 1.6
	# Body — golden-angle wrap so cells spread evenly on the cylinder surface.
	for i in body_count:
		var u: float = (0.5 if body_count <= 1
			else float(i) / float(body_count - 1))
		var ang: float = fmod(float(i) * 2.39996323, TAU)
		var y: float = (u - 0.5) * body_len
		var bulge: float = 1.0 + 0.25 * sin(u * PI)
		multimesh.set_instance_color(i, Color(
			sin(ang) * body_r * bulge, y, cos(ang) * body_r * bulge, 0.0))
	# Tentacle seed positions — straight out the top of the body.
	var idx: int = body_count
	for t in tents:
		var base_ang: float = float(t) / float(tents) * TAU
		var n: int = per_tent + (1 if t < extra else 0)
		for k in n:
			var u: float = float(k + 1) / float(n)
			var reach: float = body_r + u * 4.5
			multimesh.set_instance_color(idx, Color(
				sin(base_ang) * reach,
				body_len * 0.5 + u * 1.2,
				cos(base_ang) * reach, 0.0))
			idx += 1
	# Stash metadata for the per-frame animator.
	_hydra_tent_start = body_count
	_hydra_tents = tents
	_hydra_per_tent = per_tent
	_hydra_extra = extra
	_hydra_body_len = body_len
	_hydra_body_r = body_r

func _shape_worm(count: int) -> void:
	# Plattwurm — long thin ribbon (flatworm). Most cells distributed along
	# X-length; flat in Y; slim Z thickness. Body slithers per-frame in
	# _animate_worm.
	var length: float = 18.0
	var half_w: float = 1.2
	for i in count:
		var t: float = float(i) / float(max(1, count - 1))
		var x: float = (t - 0.5) * length
		# Cross-section: golden-angle spread on a flat ellipse so the
		# ribbon is wider in Z than tall in Y (worm seen from above).
		var ang: float = float(i) * 2.39996323
		var rad_seed: float = sqrt(float(i % 9) / 9.0)
		var taper: float = sin(t * PI) * 0.8 + 0.2  # narrower at head + tail
		var y: float = cos(ang) * rad_seed * half_w * 0.35 * taper
		var z: float = sin(ang) * rad_seed * half_w * taper
		multimesh.set_instance_color(i, Color(x, y, z, 0.0))
	_worm_count = count
	_worm_length = length
	_worm_half_w = half_w

func _shape_insect(count: int) -> void:
	# Insekt — segmented body (head, thorax, abdomen) + 6 legs + 2 antennae.
	# Body uses ~65% of cells, legs ~30%, antennae ~5%. Static silhouette.
	var body_n: int = int(float(count) * 0.65)
	var leg_n: int = int(float(count) * 0.30)
	var antenna_n: int = count - body_n - leg_n
	# Three body segments, golden-angle distributed within each ellipsoid.
	var seg_offsets: Array = [-3.2, 0.0, 3.6]  # head, thorax, abdomen along X
	var seg_radii: Array = [1.1, 1.5, 1.9]      # abdomen biggest
	var phi: float = PI * (3.0 - sqrt(5.0))
	for i in body_n:
		var seg: int = i % 3
		var local: int = i / 3
		var sub_count: int = body_n / 3 + (1 if (body_n % 3) > seg else 0)
		var y_norm: float = (0.0 if sub_count <= 1
			else 1.0 - (float(local) / float(sub_count - 1)) * 2.0)
		var cr: float = sqrt(max(0.0, 1.0 - y_norm * y_norm))
		var th: float = phi * float(i)
		var r: float = float(seg_radii[seg])
		multimesh.set_instance_color(i, Color(
			float(seg_offsets[seg]) + cos(th) * cr * r * 0.6,
			y_norm * r,
			sin(th) * cr * r, 0.0))
	# 6 legs from thorax (middle segment), 3 per side. Each leg = a short
	# line of cells angled down-and-out.
	var legs: int = 6
	var per_leg: int = leg_n / legs
	var leg_extra: int = leg_n - per_leg * legs
	var write_idx: int = body_n
	for li in legs:
		var side: float = (-1.0 if li < 3 else 1.0)  # left or right
		var slot: int = li % 3                       # which of 3 legs on this side
		# Attach point along thorax: spread the 3 legs across thorax X.
		var attach_x: float = float(seg_offsets[1]) + (float(slot) - 1.0) * 1.0
		var n: int = per_leg + (1 if li < leg_extra else 0)
		for k in n:
			var u: float = float(k + 1) / float(max(1, n))
			# Leg extends outward (Z) and downward (-Y), with mild knee bend.
			var ext_z: float = side * (1.0 + u * 2.2)
			var ext_y: float = -u * 1.8 - sin(u * PI) * 0.4
			multimesh.set_instance_color(write_idx, Color(
				attach_x, ext_y, ext_z, 1.0))  # organ-colour highlight for legs
			write_idx += 1
	# Antennae — 2 short sprays forward from head.
	for k in antenna_n:
		var u: float = float(k) / float(max(1, antenna_n - 1))
		var side: float = (-1.0 if (k % 2) == 0 else 1.0)
		multimesh.set_instance_color(write_idx, Color(
			float(seg_offsets[0]) - 0.8 - u * 1.5,
			0.6 + u * 1.0,
			side * (0.4 + u * 0.6), 1.0))
		write_idx += 1

func _shape_fish(count: int) -> void:
	# Fisch — streamlined body (prolate ellipsoid) + caudal fin (triangle
	# in XY plane) + dorsal fin (triangle on +Y). Tail cells get rewritten
	# per frame by _animate_fish_tail; body + dorsal stay put.
	var tail_n: int = int(float(count) * 0.12)
	var dorsal_n: int = int(float(count) * 0.08)
	var body_n: int = count - tail_n - dorsal_n
	var body_len: float = 9.5
	var body_h: float = 2.0
	var body_w: float = 1.6
	var phi: float = PI * (3.0 - sqrt(5.0))
	for i in body_n:
		var y_norm: float = (0.0 if body_n <= 1
			else 1.0 - (float(i) / float(body_n - 1)) * 2.0)
		var cr: float = sqrt(max(0.0, 1.0 - y_norm * y_norm))
		var th: float = phi * float(i)
		# Body tapers toward head (+X) and tail (-X) — pinch ends.
		var taper: float = pow(cr, 0.7)
		multimesh.set_instance_color(i, Color(
			y_norm * body_len * 0.5,
			cos(th) * taper * body_h,
			sin(th) * taper * body_w, 0.0))
	# Dorsal fin — triangle on +Y above body's midpoint.
	for k in dorsal_n:
		var t: float = float(k) / float(max(1, dorsal_n - 1))
		# triangle spans X roughly [-1.5, 0.5], peak height at ~Y=3.5
		var rib: float = sin(t * PI)
		multimesh.set_instance_color(body_n + k, Color(
			-1.5 + t * 2.0, body_h + rib * 1.6, 0.0, 0.0))
	# Caudal-fin seed positions — triangle behind the body. Animator sweeps
	# these left/right; we just lay them flat here.
	var tail_start: int = body_n + dorsal_n
	for k in tail_n:
		var t: float = float(k) / float(max(1, tail_n - 1))
		var rib: float = (t - 0.5) * 2.0  # -1..+1 vertical spread
		multimesh.set_instance_color(tail_start + k, Color(
			-body_len * 0.5 - 0.5 - abs(rib) * 0.8,
			rib * 2.0, 0.0, 1.0))
	_fish_tail_start = tail_start
	_fish_tail_count = tail_n
	_fish_body_len = body_len

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
		"plant":         _shape_plant(count)
		"sponge":        _shape_sponge(count)
		"hydra":         _shape_hydra(count)
		"worm":          _shape_worm(count)
		"insect":        _shape_insect(count)
		"fish":          _shape_fish(count)
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
		"hydra":
			_animate_hydra_tentacles(t)
		"worm":
			_animate_worm(t)
		"fish":
			_animate_fish_tail(t)

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

func _animate_worm(t: float) -> void:
	# Slither — sine wave traveling along the body length displaces Y.
	# Wavelength ~ body length / 2, speed ~ 1.5 cycles/sec.
	if _worm_count <= 0:
		return
	for i in _worm_count:
		var u: float = float(i) / float(max(1, _worm_count - 1))
		var x: float = (u - 0.5) * _worm_length
		# Same cross-section seed as _shape_worm — keep cells coherent.
		var ang: float = float(i) * 2.39996323
		var rad_seed: float = sqrt(float(i % 9) / 9.0)
		var taper: float = sin(u * PI) * 0.8 + 0.2
		# Slither: amplitude scales with body taper so head/tail wag less.
		var wave: float = sin(u * PI * 2.5 - t * 4.5) * 1.4 * taper
		var y: float = cos(ang) * rad_seed * _worm_half_w * 0.35 * taper + wave
		var z: float = sin(ang) * rad_seed * _worm_half_w * taper
		multimesh.set_instance_color(i, Color(x, y, z, 0.0))

func _animate_fish_tail(t: float) -> void:
	# Caudal-fin sweep — entire tail group rotates around X-axis through
	# the body's tail-attach point. Pure Z-shift suffices visually (the
	# fin's vertical spread is preserved from the seed positions).
	if _fish_tail_count <= 0:
		return
	var sweep: float = sin(t * 6.0) * 2.2
	for k in _fish_tail_count:
		var ft: float = float(k) / float(max(1, _fish_tail_count - 1))
		var rib: float = (ft - 0.5) * 2.0
		# Re-derive seed X (same formula as _shape_fish) so we don't drift.
		var seed_x: float = -_fish_body_len * 0.5 - 0.5 - abs(rib) * 0.8
		multimesh.set_instance_color(_fish_tail_start + k, Color(
			seed_x, rib * 2.0, sweep * (1.0 - abs(rib) * 0.3), 1.0))

func _animate_hydra_tentacles(t: float) -> void:
	# Each tentacle has its own phase — coordinated but not synchronised.
	# Wave amplitude grows toward the tentacle tip. Tentacles also bob
	# vertically at a different frequency so they don't look mechanical.
	var idx: int = _hydra_tent_start
	for ti in _hydra_tents:
		var base_ang: float = float(ti) / float(_hydra_tents) * TAU
		var phase: float = t * 1.1 + float(ti) * 0.9
		var n: int = _hydra_per_tent + (1 if ti < _hydra_extra else 0)
		var perp_ang: float = base_ang + PI * 0.5
		for k in n:
			var u: float = float(k + 1) / float(max(1, n))
			var reach: float = _hydra_body_r + u * 4.5
			var wave: float = sin(phase + u * 3.2) * 0.8 * u
			multimesh.set_instance_color(idx, Color(
				sin(base_ang) * reach + sin(perp_ang) * wave,
				_hydra_body_len * 0.5 + u * 1.2 + sin(phase * 0.7 + u * 2.0) * 0.35 * u,
				cos(base_ang) * reach + cos(perp_ang) * wave, 0.0))
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
