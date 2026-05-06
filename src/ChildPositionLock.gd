extends Node2D

var _global_position


func _ready() -> void:
	_global_position = global_position


func _process(_delta: float) -> void:
	global_position = _global_position


func _on_animation_finished() -> void:
	queue_free()
