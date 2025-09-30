extends HideAttribute
class_name HideSpriteAttribute

@onready var parent := get_parent()


func _ready() -> void:
	for child in parent.get_children():
		if _is_valid_sprite(child):
			child.hide()


func _exit_tree() -> void:
	for child in parent.get_children():
		if _is_valid_sprite(child):
			child.hide()
	

func _is_valid_sprite(node: Node) -> bool:
	return node is Sprite2D or node is NinePatchSprite2D or node is ReboundOrbSprite or node is ReboundPadSprite
