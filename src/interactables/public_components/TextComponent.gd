extends Component
class_name TextComponent

const DEFAULT_TEXT_SETTINGS: TextSettings = preload("res://resources/DefaultTextSettings.tres")

@export_multiline var text: String:
	set(value):
		text = value
		if _label:
			_label.text = value if not value.is_empty() else "Aa"
			update_label_size.call_deferred()
@export var horizontal_alignment: HorizontalAlignment:
	set(value):
		horizontal_alignment = value
		if _label:
			_label.horizontal_alignment = value
@export var vertical_alignment: VerticalAlignment:
	set(value):
		vertical_alignment = value
		if _label:
			_label.vertical_alignment = value
@export var settings: TextSettings:
	set(value):
		settings = value if value else DEFAULT_TEXT_SETTINGS
		if _label:
			_label.label_settings = value if value else DEFAULT_TEXT_SETTINGS
			if not text.is_empty():
				update_label_size.call_deferred()
@export var _label: Label
@export var _selection_collider: EditorSelectionCollider


func update_label_size() -> void:
	if not _label:
		return
	_label.size = _label.get_minimum_size()
	_label.position = -_label.size / 2.0
	_selection_collider.scale = _label.size / (Vector2.ONE * LevelManager.CELL_SIZE)


func _field_to_data(field_name: String) -> Variant:
	if field_name == "settings":
		return (settings if settings else DEFAULT_TEXT_SETTINGS).to_data()
	return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	if field_name == "settings":
		settings = TextSettings.from_data(field_data)
		return
	set(field_name, field_data)
