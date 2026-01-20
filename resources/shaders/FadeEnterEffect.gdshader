shader_type canvas_item;

uniform float fade_width: hint_range(0.0, 1.0, 0.01) = 0.15;
uniform float gradient_start: hint_range(0.0, 1.0, 0.01) = 0.01;
uniform float gradient_end: hint_range(0.0, 1.0, 0.01) = 1.0;

// Multi-pass shader
uniform bool use_canvas_group = false;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

varying vec2 screen_position;

void vertex() {
	screen_position = (SCREEN_MATRIX * CANVAS_MATRIX * MODEL_MATRIX * vec4(vec2(0.0), 0.0, 1.0)).xy;
}

void fragment() {
	if (use_canvas_group) {
		vec4 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0);
		if (screen_color.a > 0.0001) {
			screen_color.rgb /= screen_color.a;
		}
		COLOR *= screen_color;
	}

	float fade_gradient = (1.0 - abs(screen_position.x)) * (1.0 / (fade_width * 2.0));
	fade_gradient = 1.0 - pow(1.0 - clamp(fade_gradient, 0.0, 1.0), 2.0);
	COLOR.a *= fade_gradient;
}
