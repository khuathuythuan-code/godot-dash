extends MarginContainer

@export var editor_camera: Node

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		queue_free()

func _on_swipe_toggled(toggled_on: bool) -> void:
	editor_camera.swipe = toggled_on
