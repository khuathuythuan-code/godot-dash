extends MarginContainer

@export var editor_camera: Node

func _ready() -> void:
	if not Config.config.touch_screen:
		queue_free()

func _on_swipe_toggled(toggled_on: bool) -> void:
	editor_camera.swipe = toggled_on
