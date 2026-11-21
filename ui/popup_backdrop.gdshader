shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_lod = 2.0;
uniform vec4 tint : source_color = vec4(0.02, 0.08, 0.12, 0.66);
void fragment() {
	vec3 backdrop = textureLod(screen_texture, SCREEN_UV, blur_lod).rgb;
	COLOR = vec4(mix(backdrop, tint.rgb, tint.a), 1.0);
}
