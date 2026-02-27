shader_type canvas_item;

global uniform bool menu_blur = true;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float lod: hint_range(0.0, 5) = 0.0;
uniform float lightness: hint_range(0.0, 1.0, 0.01) = 0.5;


vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void fragment() {
	vec4 color;
	float alpha = 1.0;
	if (menu_blur) {
		color = texture(SCREEN_TEXTURE, SCREEN_UV, lod) * lightness;
	} else {
		color = texture(SCREEN_TEXTURE, SCREEN_UV) * lightness;
		alpha = 1.2;
	}
	float use_original_color = step(rgb2hsv(COLOR.xyz).z, 0.3);
	COLOR.rgb = mix(COLOR.rgb, color.rgb, use_original_color);
	COLOR.a = mix(COLOR.a, alpha, use_original_color);
}