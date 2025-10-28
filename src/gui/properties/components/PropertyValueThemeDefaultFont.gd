extends Node
class_name PropertyValueThemeDefaultFont

@onready var parent: FileProperty = get_parent()


func _ready() -> void:
	var font_path: String = parent.get_theme_default_font().resource_path
	parent.set_deferred(&"default", font_path)
	parent.set_value.call_deferred(font_path)
	parent.refresh.call_deferred()
