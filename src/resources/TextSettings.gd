class_name TextSettings
extends LabelSettings

@export var _font_path: String:
	set = set_font_path

var prevent_history_action: bool = false


func _init(path: String = "") -> void:
	set_font_path(path)


func set_font_path(path: String = "") -> void:
	var is_changing_default_font: bool = path.is_empty() and _font_path.is_empty()
	if LevelManager.current_level and path.is_empty():
		if is_changing_default_font:
			prevent_history_action = true
			changed.connect(
				func(): prevent_history_action = false,
				CONNECT_DEFERRED | CONNECT_ONE_SHOT,
			)
		font = AssetManager.load_font(LevelManager.current_level.default_font)
		var default_font_changed: Signal = LevelManager.current_level.default_font_changed
		if not default_font_changed.is_connected(set_font_path):
			default_font_changed.connect(set_font_path)
	else:
		if not (path.is_empty() or path.begins_with("res://")) and LevelManager.current_level:
			LevelManager.current_level.register_required_font(_font_path, path)
			var default_font_changed: Signal = LevelManager.current_level.default_font_changed
			if default_font_changed.is_connected(set_font_path):
				default_font_changed.disconnect(set_font_path)
		font = AssetManager.load_font(path)
	_font_path = path


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
	var text_settings := TextSettings.new(data._font_path)
	text_settings.line_spacing = data.line_spacing
	text_settings.paragraph_spacing = data.paragraph_spacing
	text_settings.font_size = data.font_size
	text_settings.font_color = Color.hex(data.font_color)
	text_settings.outline_size = data.outline_size
	text_settings.outline_color = Color.hex(data.outline_color)
	text_settings.shadow_size = data.shadow_size
	text_settings.shadow_color = Color.hex(data.shadow_color)
	text_settings.shadow_offset = Deserialize.Vector2(data.shadow_offset)
	return text_settings
