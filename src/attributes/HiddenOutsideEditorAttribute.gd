extends Attribute

class_name HiddenOutsideEditorAttribute

func _ready() -> void:
	var parent: Node2D = get_parent()
	parent.visible = Editor.in_editor
