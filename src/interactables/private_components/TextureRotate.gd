extends Node
class_name TextureRotate

@export var sprite: Sprite2D
@export_range(-360.0, 360.0, 0.01, "or_greater", "or_less") var rotation_rate_degrees: float


func _process(delta: float) -> void:
	sprite.rotation_degrees += rotation_rate_degrees * delta
