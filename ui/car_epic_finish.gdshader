shader_type spatial;
// A native PBR finish keeps the Shop and rotatable Garage car identical.
uniform vec4 base_color : source_color = vec4(0.1, 0.6, 1.0, 1.0);
uniform vec4 ink_color : source_color = vec4(1.0);
uniform int finish = 0; // 0: car stripes, 1: aurora, 2: solar, 3: midnight, 4: other pearl
uniform bool canopy = false;
varying vec3 panel;
varying vec3 panel_normal;

void vertex() {
	panel = VERTEX;
	panel_normal = NORMAL;
}

void fragment() {
	vec3 paint = base_color.rgb;
	float top = smoothstep(0.2, 0.65, panel_normal.y);
	float stripes = smoothstep(0.055, 0.075, abs(panel.x)) * (1.0 - smoothstep(0.24, 0.26, abs(panel.x)));
	vec3 ink = finish == 3 ? ink_color.rgb : vec3(0.96, 0.98, 1.0);
	float mark = top * stripes;
	if (finish == 1) {
		float wave = sin(panel.x * 2.7 + panel.z * 2.5 + panel.y * 3.0);
		paint = mix(vec3(0.03, 0.8, 0.94), vec3(0.63, 0.12, 0.86), wave * 0.5 + 0.5);
		float sweep = sin(panel.z * 5.0 + panel.y * 7.0);
		mark = max(mark * 0.7, step(0.65, abs(panel_normal.x)) * (1.0-smoothstep(0.10, 0.16, abs(sweep))));
	} else if (finish == 2) {
		float tongue = abs(panel.x + 0.12 * sin(panel.z * 6.0));
		float flame = (1.0-smoothstep(0.13, 0.26, tongue)) * (1.0-smoothstep(-1.3, 0.45, panel.z));
		mark = top * flame;
		mark = max(mark, step(0.7, abs(panel_normal.x)) * (1.0-smoothstep(0.06, 0.13, abs(panel.y-0.56-0.10*sin(panel.z*7.0)))));
		ink = ink_color.rgb;
	} else if (finish == 4) {
		mark *= 0.6;
		ink = ink_color.rgb;
	}
	// The painted windshield rim stays solid; roof stripes begin above the glass.
	if (canopy) { mark *= step(-0.20, panel.z); }
	ALBEDO = mix(paint, ink, mark);
	ROUGHNESS = 0.25;
	METALLIC = finish == 1 ? 0.22 : 0.04;
	CLEARCOAT = 0.65;
	CLEARCOAT_ROUGHNESS = 0.22;
}
