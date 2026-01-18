shader_type canvas_item;
uniform float FADE: hint_range(0.0, 1.0, 0.01) = 0.1;

void fragment() {
	float screen_width = 1.0 / SCREEN_PIXEL_SIZE.x;
	float fade = FADE / SCREEN_PIXEL_SIZE.x;

	if (FRAGCOORD.x < fade) {
		COLOR.a *= FRAGCOORD.x / fade;
	} else if (FRAGCOORD.x > screen_width - fade) {
		COLOR.a *= (screen_width - FRAGCOORD.x) / fade;
	}
}
