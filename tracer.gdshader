shader_type spatial;
render_mode unshaded;
uniform float alpha = 1.0;

void vertex() {
	float t = TIME;
	float i = float(VERTEX_ID);
	VERTEX.x += sin(8.0 * t + i * 1.5) * 0.03;
	VERTEX.z += sin(9.0 * t + i) * 0.03;
}

void fragment() {
	ALBEDO = vec3(234.0 / 255.0, 220.0 / 255.0, 167.0 / 255.0);
	ALPHA = alpha;
}
