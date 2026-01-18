shader_type canvas_item;

uniform float fade_pixels = 250.0;

void fragment() {
	float screen_width = 1.0 / SCREEN_PIXEL_SIZE.x;

	if (FRAGCOORD.x < fade_pixels) {
		COLOR.a *= FRAGCOORD.x / fade_pixels;
	} else if (FRAGCOORD.x > screen_width - fade_pixels) {
		COLOR.a *= (screen_width - FRAGCOORD.x) / fade_pixels;
	}
}
