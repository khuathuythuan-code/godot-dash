extends MusicScaleAttribute
class_name MusicScaleSpriteAttribute

@onready var parent := get_parent()


func _ready() -> void:
	for child in parent.get_children():
		if _is_valid_sprite(child):
			NodeUtils.get_node_or_add(child, "MusicScale", MusicScale)
			if child is NinePatchSprite2D:
				var absolute := parent.get_node_or_null("NinePatchSprite2DAbsoluteSize")
				if absolute:
					absolute.process_mode = Node.PROCESS_MODE_DISABLED


func _exit_tree() -> void:
	for child in parent.get_children():
		if _is_valid_sprite(child):
			var attribute := child.get_node_or_null(^"MusicScaleSpriteAttribute")
			if attribute: attribute.queue_free()
			if child is NinePatchSprite2D:
				var absolute := parent.get_node_or_null("NinePatchSprite2DAbsoluteSize")
				if absolute:
					absolute.process_mode = Node.PROCESS_MODE_INHERIT				
	

func _is_valid_sprite(node: Node) -> bool:
	return node is Sprite2D or node is NinePatchSprite2D or node is ReboundOrbSprite or node is ReboundPadSprite
