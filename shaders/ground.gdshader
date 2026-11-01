shader_type spatial;
// Stylized battlefield ground: layered value noise for dust/ash variation,
// an anti-aliased tactical grid, and a dark falloff outside the playable area.

uniform vec3 base_color : source_color = vec3(0.13, 0.14, 0.16);
uniform vec3 dust_color : source_color = vec3(0.27, 0.23, 0.2);
uniform vec3 ash_color : source_color = vec3(0.08, 0.085, 0.1);
uniform vec3 grid_color : source_color = vec3(0.25, 0.82, 0.88);
uniform float grid_size = 4.0;
uniform float grid_strength = 0.18;
uniform vec2 play_half_extents = vec2(60.0, 60.0);
uniform float edge_falloff = 18.0;

varying vec3 world_pos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float n = value_noise(p * 0.04) * 0.55 + value_noise(p * 0.17) * 0.3 + value_noise(p * 0.9) * 0.15;
	vec3 col = mix(base_color, dust_color, smoothstep(0.45, 0.8, n));
	col = mix(col, ash_color, smoothstep(0.42, 0.2, n) * 0.7);

	vec2 cell = p / grid_size;
	vec2 fw = fwidth(cell);
	vec2 g = abs(fract(cell - 0.5) - 0.5) / max(fw, vec2(0.0001));
	float line = 1.0 - min(min(g.x, g.y), 1.0);

	vec2 outside = max(abs(p) - play_half_extents, vec2(0.0));
	float edge = clamp(length(outside) / edge_falloff, 0.0, 1.0);
	float inside = 1.0 - edge;

	ALBEDO = col * mix(1.0, 0.25, edge);
	ROUGHNESS = 0.92;
	SPECULAR = 0.3;
	EMISSION = grid_color * line * grid_strength * inside;
}
