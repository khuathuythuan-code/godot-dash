extends Component
class_name TextComponent

const DEFAULT_LABEL_SETTINGS: LabelSettings = preload("res://resources/DefaultTextLabelSettings.tres")

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
@export var settings: LabelSettings:
	set(value):
		settings = value if value else DEFAULT_LABEL_SETTINGS
		if _label:
			_label.label_settings = value if value else DEFAULT_LABEL_SETTINGS
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
