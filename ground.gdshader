shader_type spatial;
render_mode unshaded, blend_mix;

uniform sampler2D texture: source_color;
uniform vec3 albedo: source_color;

void fragment() {
	vec2 v1 = UV * 50.0;
	vec2 v2 = UV * 100.0;
	float r1 = pow(texture(texture, v1).r, 2.0);
	float r2 = pow(texture(texture, v2).r, 4.0);
	float r = r1 * 0.2 - r2 * 0.01;
	ALBEDO = vec3(r);
	ALPHA = (r1 + r2) / 1.5;
}
