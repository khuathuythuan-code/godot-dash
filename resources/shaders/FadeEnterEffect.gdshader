shader_type canvas_item;

uniform int mode : hint_enum("Disabled", "Fade", "Fade and move down", "Fade and scale") = 1;
uniform float fade_width: hint_range(0.0, 1.0, 0.01) = 0.15;
uniform float gradient_start: hint_range(0.0, 1.0, 0.01) = 0.01;
uniform float gradient_end: hint_range(0.0, 1.0, 0.01) = 1.0;

// Multi-pass shader
uniform bool use_canvas_group = false;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

varying vec2 screen_position;
varying vec2 screen_uv;

vec4 fade_color(vec4 color) {
	float fade_gradient = (1.0 - abs(screen_position.x)) * (1.0 / (fade_width * 2.0));
	fade_gradient = 1.0 - pow(1.0 - clamp(fade_gradient, 0.0, 1.0), 2.0);
	color.a *= fade_gradient;
	return color;
}

void vertex() {
	screen_position = (SCREEN_MATRIX * CANVAS_MATRIX * MODEL_MATRIX * vec4(vec2(0.0), 0.0, 1.0)).xy;
	screen_uv = (SCREEN_MATRIX * CANVAS_MATRIX * MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy * 0.5 + 0.5;
	float power = (1.0 - abs(screen_position.x)) * (1.0 / (fade_width * 2.0));
	power = 1.0 - pow(1.0 - clamp(power, 0.0, 1.0), 2.0);
	switch (mode) {
		case 2: // Fade and move up
			VERTEX.y -= (1.0 - power) * 1000.0;
			break;
		case 3: // Fade and scale
			VERTEX *= power;
			break;
	}
}

void fragment() {
	if (use_canvas_group) {
		vec4 screen_color = textureLod(screen_texture, screen_uv, 0.0);
		if (screen_color.a > 0.0001) {
			screen_color.rgb /= screen_color.a;
		}
		COLOR *= screen_color;
	}
	switch (mode) {
		case 0: // Disabled
			break;
		case 1:
			COLOR = fade_color(COLOR);
			break;
		case 2:
			COLOR = fade_color(COLOR);
			break;
		case 3:
			COLOR = fade_color(COLOR);
			break;
	}
}
