extends Node

const Direction = DirectionChangerComponent.Direction

@export var music_scale: MusicScale

@onready var parent := get_parent() as Sprite2D

var flipped: bool


func _process(_delta: float) -> void:
	_update_flip()


func _update_flip() -> void:
	var flip_multiplier: int = -1 if flipped or absf(parent.get_parent().rotation) > PI / 4 else 1
	(
		func():
			parent.scale.x = absf(parent.scale.x) * flip_multiplier
			if music_scale:
				music_scale.initial_scale.x = absf(music_scale.initial_scale.x) * flip_multiplier
	).call_deferred()


func _on_direction_changed(new_direction: Direction) -> void:
	match new_direction:
		Direction.KEEP, Direction.FORWARDS:
			flipped = false
		Direction.FLIP, Direction.BACKWARDS:
			flipped = true
