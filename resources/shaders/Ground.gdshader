shader_type canvas_item;

uniform vec3 ground_color : source_color = vec3(1.0);

void fragment() {
	float shadow = SCREEN_UV.x;
	float shadow_left = shadow * 3.0;
	float shadow_right = (1.0 - shadow) * 3.0;
	shadow = mix(0.1, 1.0, shadow_left * shadow_right);
	shadow = clamp(shadow, 0.0, 1.0);
	float shine = 1.0 - abs(SCREEN_UV.x - 0.5) * 5.0;
	shine = clamp(shine, 0.0, 1.0) * (1.0-step(0.005, UV.y));
	COLOR.rgb *= shadow;
	COLOR.rgb = mix(COLOR.rgb, ground_color, shine);
}