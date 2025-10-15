shader_type canvas_item;

global uniform bool menu_blur = true;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float lod: hint_range(0.0, 5) = 0.0;
uniform vec4 gui_color: source_color;
uniform float mix_factor: hint_range(0.0, 1.0, 0.01);

void fragment() {
	if (menu_blur) {
    float average = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
    if (COLOR.r == average && COLOR.g == average && COLOR.b == average && round(average * 3.0) != 3.0) {
        vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
        color = mix(color, gui_color, mix_factor);
        COLOR = color;
		}
    }
}