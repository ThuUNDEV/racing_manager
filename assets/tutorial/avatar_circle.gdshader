shader_type canvas_item;

varying vec2 portrait_position;

void vertex() {
	portrait_position = VERTEX;
}

void fragment() {
	vec4 portrait = texture(TEXTURE, UV);
	float radius = length(portrait_position - vec2(28.0));
	COLOR = vec4(portrait.rgb, portrait.a * (1.0 - smoothstep(27.0, 28.0, radius)));
}
