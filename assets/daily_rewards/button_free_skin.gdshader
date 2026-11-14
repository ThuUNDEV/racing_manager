shader_type canvas_item;

varying vec4 canvas_tint;

void vertex() {
	canvas_tint = COLOR;
}

// Reconstruct only the background beneath the baked claim button. The live
// Button draws the shared face; the rest of the supplied popup art stays intact.
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 point = UV * vec2(922.0, 1706.0);
	if (point.x > 111.0 && point.x < 815.0 && point.y > 1498.0 && point.y < 1619.0) {
		vec4 left = texture(TEXTURE, vec2(111.0 / 922.0, UV.y));
		vec4 right = texture(TEXTURE, vec2(815.0 / 922.0, UV.y));
		color = mix(left, right, (point.x - 111.0) / 704.0);
	}
	// Fragment COLOR already contains the original texture sample. Use only
	// the canvas tint here so the baked green face cannot bleed back through.
	COLOR = color * canvas_tint;
}
