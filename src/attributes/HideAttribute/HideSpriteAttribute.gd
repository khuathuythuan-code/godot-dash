extends HideAttribute
class_name HideSpriteAttribute
@onready var parent := get_parent().get_children()

func _ready() -> void:
	for node in parent:
		if node and (node is Sprite2D or (node.name.contains("Sprite") and node is Node2D)):
			node.hide()
			continue



func _exit_tree() -> void:
	for node in parent:
		if node and (node is Sprite2D or (node.name.contains("Sprite") and node is Node2D)):
			node.show()
			continue
