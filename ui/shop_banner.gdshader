shader_type canvas_item;
uniform vec2 rect_size = vec2(330.0, 110.0);
uniform float radius = 12.0;

void fragment() {
	vec2 q = abs(UV * rect_size - rect_size * 0.5) - rect_size * 0.5 + vec2(radius);
	float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	COLOR.a *= 1.0 - smoothstep(-0.75, 0.75, distance_to_edge);
}
