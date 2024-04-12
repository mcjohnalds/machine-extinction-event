shader_type spatial;
render_mode unshaded;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear;
uniform float texture_scale = 1.0;

void vertex() {
	UV *= texture_scale;
}

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	// sRGB conversion
	albedo_tex.rgb = mix(
		pow((albedo_tex.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)),
		albedo_tex.rgb.rgb * (1.0 / 12.92),
		lessThan(albedo_tex.rgb, vec3(0.04045))
	);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
}
