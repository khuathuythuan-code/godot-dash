shader_type canvas_item;
#include "Color.gdshaderinc"

instance uniform float added_hue;

void fragment() {
	vec3 hsv = rgb_to_hsv(COLOR.rgb);
	hsv.x += added_hue;
	COLOR.rgb = hsv_to_rgb(hsv);
}
