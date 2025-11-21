extends Node
class_name NinePatchSprite2DAbsoluteSize

@export var nine_patch_sprite: NinePatchSprite2D
@onready var parent := get_parent() as Node2D


func _process(_delta: float) -> void:
	if NodeUtils.is_on_screen(parent, Constants.Axis.X):
		_on_size_changed()


func _on_size_changed() -> void:
	print("cahnged")
	nine_patch_sprite.global_scale = Vector2.ONE/4
	nine_patch_sprite.size = abs(parent.global_scale) * 512
