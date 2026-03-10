extends Node
class_name NinePatchSprite2DAbsoluteSize

@export var nine_patch_sprite: NinePatchSprite2D
@export var scale: Vector2 = Vector2.ONE
@onready var parent := get_parent() as Node2D


func _process(_delta: float) -> void:
	_on_size_changed()


func _on_size_changed() -> void:
	nine_patch_sprite.global_scale = Vector2.ONE/4
	nine_patch_sprite.size = abs(parent.global_scale) * 512 * scale
