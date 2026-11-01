shader_type spatial;
// Stylized battlefield ground: layered value noise for dust/ash variation,
// an anti-aliased two-level tactical grid that fades with view distance, and a
// dark falloff outside the playable area.

uniform vec3 base_color : source_color = vec3(0.2, 0.215, 0.235);
uniform vec3 dust_color : source_color = vec3(0.31, 0.29, 0.27);
uniform vec3 ash_color : source_color = vec3(0.12, 0.13, 0.15);
uniform vec3 grid_color : source_color = vec3(0.25, 0.82, 0.88);
uniform float minor_grid_size = 4.0;
uniform float major_grid_size = 16.0;
uniform float minor_grid_strength = 0.035;
uniform float major_grid_strength = 0.11;
uniform float grid_fade_start = 45.0;
uniform float grid_fade_end = 140.0;
uniform vec2 play_half_extents = vec2(60.0, 60.0);
uniform float edge_falloff = 22.0;

varying vec3 world_pos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float grid_line(vec2 p, float size) {
	vec2 cell = p / size;
	vec2 fw = max(fwidth(cell), vec2(0.0001));
	vec2 g = abs(fract(cell - 0.5) - 0.5) / fw;
	return 1.0 - min(min(g.x, g.y), 1.0);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float n = value_noise(p * 0.03) * 0.55 + value_noise(p * 0.11) * 0.3 + value_noise(p * 0.5) * 0.15;
	vec3 col = mix(base_color, dust_color, smoothstep(0.5, 0.78, n));
	col = mix(col, ash_color, smoothstep(0.4, 0.22, n) * 0.6);
	// Fine grain keeps large flat areas from looking plastic.
	col *= 0.94 + value_noise(p * 3.0) * 0.08;

	vec2 outside = max(abs(p) - play_half_extents, vec2(0.0));
	float edge = clamp(length(outside) / edge_falloff, 0.0, 1.0);
	float view_fade = 1.0 - smoothstep(grid_fade_start, grid_fade_end, length(VERTEX));
	float grid = grid_line(p, minor_grid_size) * minor_grid_strength + grid_line(p, major_grid_size) * major_grid_strength;

	ALBEDO = col * mix(1.0, 0.35, edge);
	ROUGHNESS = 0.9;
	SPECULAR = 0.35;
	EMISSION = grid_color * grid * view_fade * (1.0 - edge);
}
