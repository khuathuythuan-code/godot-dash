extends Node
class_name MusicScale

@onready var parent: Node2D = get_parent()
@onready var initial_scale: Vector2 = parent.scale
@onready var music_scale: float = find_parent("GameScene").music_scale

func _process(delta):
	parent.scale = parent.scale.lerp(initial_scale * (music_scale), 1-exp(-delta * 12))
