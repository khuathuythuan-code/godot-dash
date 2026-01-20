shader_type canvas_item;

uniform float FADE: hint_range(0.0, 1.0, 0.01) = 0.075;
uniform float gradient_start: hint_range(0.0, 1.0, 0.01) = 0.01;
uniform float gradient_end: hint_range(0.0, 1.0, 0.01) = 1.0;

uniform bool use_canvas_group = false;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	float screen_width = 1.0 / SCREEN_PIXEL_SIZE.x;
	float fade = FADE / SCREEN_PIXEL_SIZE.x;

	if (FRAGCOORD.x < fade) {
		COLOR.a *= smoothstep(gradient_start, gradient_end, FRAGCOORD.x / fade);
	} else if (FRAGCOORD.x > screen_width - fade) {
		COLOR.a *= smoothstep(gradient_start, gradient_end, (screen_width - FRAGCOORD.x) / fade);
	}

	if (use_canvas_group) {
		vec4 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0);
		if (screen_color.a > 0.0001) {
			screen_color.rgb /= screen_color.a;
		}
		COLOR *= screen_color;
	}
}
