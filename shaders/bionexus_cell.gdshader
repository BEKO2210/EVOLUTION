// BioNexus cell shader — Phase 1 / P1-010.
//
// Port of the HTML/Three.js prototype shader (see index.html, vertexShader
// and fragmentShader constants). The full feature set from the prototype is
// preserved: per-instance wobble via simplex noise, cluster <-> organism
// morph, swimming undulation, click shockwave, additive Fresnel rim.
//
// MultiMesh wiring (configured in scripts/cell/bionexus.gd):
//   - use_colors      = true   → INSTANCE_COLOR.rgb carries targetPos,
//                                 INSTANCE_COLOR.a carries cellType (0=membrane,
//                                 1=organ)
//   - use_custom_data = true   → INSTANCE_CUSTOM.x carries clusterOffset
//   - per-instance transform   → automatically applied to VERTEX by Godot
//
// Render mode mirrors the prototype's additive blending + no depth write so
// the cluster gives the "metaball / x-ray" effect.
shader_type spatial;
render_mode blend_add, depth_draw_never, depth_test_disabled, unshaded, cull_disabled;

// --- Time / morph / swim / shockwave uniforms ------------------------------
uniform float time = 0.0;
uniform float morph : hint_range(0.0, 1.0) = 0.0;
uniform float swim : hint_range(0.0, 1.0) = 0.0;
uniform vec3  click_pos = vec3(0.0);
uniform float click_strength = 0.0;

// Stage-signature heartbeat (0..1). Written by bionexus.gd per frame based on
// the active stage's signature animation (plasma / breathe / throb / swim /
// hunt / glide / basepair / flow / tumble / shimmer). Mirrors the HTML
// prototype's bodyPulse uniform so both renderers feel the same.
uniform float body_pulse : hint_range(0.0, 1.0) = 0.0;

// --- Palette ---------------------------------------------------------------
uniform vec3 color_membrane : source_color = vec3(0.0, 1.0, 0.64);  // accent green
uniform vec3 color_organ    : source_color = vec3(1.0, 0.82, 0.29); // gold
uniform vec3 color_glow     : source_color = vec3(0.31, 0.82, 1.0); // cyan

// --- Simplex 3D noise (Ashima / Stefan Gustavson, public-domain) -----------
vec3 mod289(vec3 x){return x-floor(x*(1.0/289.0))*289.0;}
vec4 mod289_v4(vec4 x){return x-floor(x*(1.0/289.0))*289.0;}
vec4 permute(vec4 x){return mod289_v4(((x*34.0)+1.0)*x);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314*r;}
float snoise(vec3 v) {
	const vec2 C = vec2(1.0/6.0, 1.0/3.0);
	const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
	vec3 i  = floor(v + dot(v, C.yyy));
	vec3 x0 = v - i + dot(i, C.xxx);
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);
	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy;
	vec3 x3 = x0 - D.yyy;
	i = mod289(i);
	vec4 p = permute(permute(permute(i.z + vec4(0.0, i1.z, i2.z, 1.0))
		+ i.y + vec4(0.0, i1.y, i2.y, 1.0))
		+ i.x + vec4(0.0, i1.x, i2.x, 1.0));
	float n_ = 0.142857142857;
	vec3 ns = n_ * D.wyz - D.xzx;
	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);
	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);
	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);
	vec4 s0 = floor(b0) * 2.0 + 1.0;
	vec4 s1 = floor(b1) * 2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));
	vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
	vec3 p0 = vec3(a0.xy, h.x);
	vec3 p1 = vec3(a0.zw, h.y);
	vec3 p2 = vec3(a1.xy, h.z);
	vec3 p3 = vec3(a1.zw, h.w);
	vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
	p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
	vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
	m = m * m;
	return 42.0 * dot(m * m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

// --- Varyings --------------------------------------------------------------
varying float v_cell_type;
varying float v_glow;

void vertex() {
	// Unpack per-instance data from MultiMesh.
	vec3 target_pos      = INSTANCE_CUSTOM.xyz;   // organism position
	float cluster_offset = INSTANCE_CUSTOM.w;     // noise phase per instance
	float cell_type      = COLOR.a;               // 0=membrane, 1=organ
	v_cell_type = cell_type;

	// 1) Per-cell membrane wobble — each instance breathes on its own phase.
	float wob = snoise(VERTEX * 4.0 + time * 2.2 + cluster_offset) * 0.18;
	vec3 local_pos = VERTEX + NORMAL * wob;

	// 2) Cluster (instance transform) ↔ organism morph.
	//    cluster_pos is the translation column of MODEL_MATRIX (per-instance).
	vec4 world_local  = MODEL_MATRIX * vec4(local_pos, 1.0);
	vec3 cluster_pos  = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float m = morph * morph * (3.0 - 2.0 * morph);  // smoothstep
	vec3 base_pos = mix(cluster_pos, target_pos, m);

	// 3) Swimming undulation, only when swim > 0.
	float phase = base_pos.x * 0.25 - time * 3.0;
	base_pos.y += sin(phase) * 4.0 * swim;
	base_pos.z += cos(phase * 0.8) * 2.0 * swim;
	base_pos.x += sin(time * 5.0 + base_pos.x * 0.5) * 0.2 * swim;

	// world_local carries the scaled+rotated mesh offset around cluster_pos.
	vec3 mesh_offset = world_local.xyz - cluster_pos;
	vec3 final_pos = base_pos + mesh_offset;

	// 4) Click shockwave — radial push from click_pos, decays with strength.
	float d = distance(base_pos, click_pos);
	float wave = exp(-d * 0.55) * click_strength;
	vec3 outward = normalize(base_pos - click_pos + vec3(0.0001));
	final_pos += outward * wave * 1.8;
	v_glow = wave;

	// Skip Godot's auto MODEL_MATRIX transform since we already applied it.
	VERTEX = (inverse(MODEL_MATRIX) * vec4(final_pos, 1.0)).xyz;
	// Approximate per-instance normal (cheap; Fresnel only needs general direction)
	NORMAL = normalize(NORMAL);
}

void fragment() {
	// Fresnel using world-view direction.
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float rim = 1.0 - max(dot(v, n), 0.0);
	float fresnel = smoothstep(0.25, 1.0, rim);
	float inner = pow(1.0 - rim, 3.0) * 0.35;

	vec3 base = mix(color_membrane, color_organ, v_cell_type);
	if (v_cell_type > 0.5) {
		base *= 1.0 + sin(time * 2.0) * 0.25;
		fresnel = smoothstep(0.08, 1.0, rim);
	}

	// Stage-signature heartbeat — brightens membrane in sync with the active
	// per-stage animation (driven from bionexus.gd, mirrors HTML bodyPulse).
	base *= 1.0 + body_pulse * 0.45;

	vec3 col = base * (fresnel * 1.6 + inner);
	// Click flash — bright cyan halo on cells inside the shockwave.
	col += color_glow * v_glow * 1.4;
	// Signature heartbeat leaks a hint of glow colour so a pulse on a still
	// cluster reads as more than just brightness.
	col += color_glow * body_pulse * 0.15;

	float alpha = clamp(fresnel + inner + v_glow * 0.6, 0.0, 1.0);

	// unshaded render_mode: write directly to ALBEDO and ALPHA.
	ALBEDO = col;
	ALPHA = alpha;
}
