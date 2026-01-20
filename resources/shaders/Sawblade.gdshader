shader_type canvas_item;

uniform float gradient_start: hint_range(0.0, 1.0, 0.01);
uniform float gradient_end: hint_range(0.0, 1.0, 0.01);

uniform float FADE: hint_range(0.0, 1.0, 0.01) = 0.075;
uniform float gradient_start_fade: hint_range(0.0, 1.0, 0.01) = 0.01;
uniform float gradient_end_fade: hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	COLOR.a *= smoothstep(
		gradient_start,
		gradient_end,
		length(uv)
	);

	// Fade Enter Effect
	float screen_width = 1.0 / SCREEN_PIXEL_SIZE.x;
	float fade = FADE / SCREEN_PIXEL_SIZE.x;

	if (FRAGCOORD.x < fade) {
		COLOR.a *= smoothstep(gradient_start_fade, gradient_end_fade, FRAGCOORD.x / fade);
	} else if (FRAGCOORD.x > screen_width - fade) {
		COLOR.a *= smoothstep(gradient_start_fade, gradient_end_fade, (screen_width - FRAGCOORD.x) / fade);
	}
}