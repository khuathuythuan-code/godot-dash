extends LabelSettings
class_name TextSettings

@export var _font_path: String:
	set(value):
		if not value.begins_with("res://") and LevelManager.current_level:
			LevelManager.current_level.register_required_font(_font_path, value)
		_font_path = value
		if LevelManager.current_level and _font_path.is_empty():
			font = LevelAssetManager.load_font(LevelManager.current_level.default_font)
		else:
			font = LevelAssetManager.load_font(_font_path)


func _init() -> void:
	_font_path = _font_path


func to_data() -> Dictionary:
	var data: Dictionary
	data.line_spacing = line_spacing
	data.paragraph_spacing = paragraph_spacing
	data.font_size = font_size
	data.font_color = font_color.to_rgba32()
	data.outline_size = outline_size
	data.outline_color = outline_color.to_rgba32()
	data.shadow_size = shadow_size
	data.shadow_color = shadow_color.to_rgba32()
	data.shadow_offset = Serialize.Vector2(shadow_offset)
	data._font_path = _font_path if not _font_path.begins_with("res://") else ""
	return data


static func from_data(data: Dictionary) -> TextSettings:
	var text_settings := TextSettings.new()
	text_settings.line_spacing = data.line_spacing
	text_settings.paragraph_spacing = data.paragraph_spacing
	text_settings.font_size = data.font_size
	text_settings.font_color = Color.hex(data.font_color)
	text_settings.outline_size = data.outline_size
	text_settings.outline_color = Color.hex(data.outline_color)
	text_settings.shadow_size = data.shadow_size
	text_settings.shadow_color = Color.hex(data.shadow_color)
	text_settings.shadow_offset = Deserialize.Vector2(data.shadow_offset)
	text_settings._font_path = data._font_path
	return text_settings
