shader_type canvas_item;
uniform vec4 paint_color : source_color = vec4(1.0);
varying vec4 vertex_color;
void vertex() {
	vertex_color = COLOR;
}
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float hi = max(source.r, max(source.g, source.b));
	float lo = min(source.r, min(source.g, source.b));
	float saturation = (hi - lo) / max(hi, 0.001);
	// Neutral silver body only; preserve blue glazing, orange trim and dark wheels.
	float body = (1.0 - smoothstep(0.12, 0.28, saturation)) * smoothstep(0.28, 0.52, hi);
	vec3 painted = paint_color.rgb * (0.36 + 0.64 * hi);
	painted = mix(painted, vec3(1.0), smoothstep(0.86, 1.0, hi) * 0.4);
	COLOR = vertex_color * vec4(mix(source.rgb, painted, body), source.a);
}
