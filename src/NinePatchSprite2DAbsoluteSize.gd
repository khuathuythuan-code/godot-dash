@tool
extends Node
class_name NinePatchSprite2DAbsoluteSize

@onready var last_scale: Vector2
@export var nine_patch_sprite: NinePatchSprite2D
@onready var parent := get_parent() as Node

func _ready() -> void:
	_on_size_changed()

func _process(_delta: float) -> void:
	if last_scale == parent.global_scale:
		last_scale = parent.global_scale
		return
	last_scale = parent.global_scale
	_on_size_changed()

func _on_size_changed() -> void:
	nine_patch_sprite.set_deferred("global_scale", Vector2.ONE/4)
	nine_patch_sprite.set_deferred("size", abs(parent.global_scale) * 512)
