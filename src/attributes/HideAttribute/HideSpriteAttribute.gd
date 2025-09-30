extends HideAttribute
class_name HideSpriteAttribute
@onready var parent := get_parent().get_children()

func _ready() -> void:
	for node in parent:
		if node and node.get_class() == "Sprite2D" or node.name.contains("Sprite") and not node.name == "NinePatchSprite2DAbsoluteSize" and not node.get_name() == "HideSpriteAttribute":
			hide_safe(node)
			continue
		parent.remove_at(parent.find(node))


func _exit_tree() -> void:
	for node in parent:
		if node and node.get_class() == "Sprite2D" or node.name.contains("Sprite") and not node.name == "NinePatchSprite2DAbsoluteSize" and not node.get_name() == "HideSpriteAttribute":
			show_safe(node)
			continue
