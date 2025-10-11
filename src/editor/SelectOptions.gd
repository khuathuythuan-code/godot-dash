extends MarginContainer

@export var EditorCamera: Node

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		queue_free()

func _on_swipe_toggled(toggled_on: bool) -> void:
	EditorCamera.swipe = toggled_on
