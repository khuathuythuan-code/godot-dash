extends MarginContainer

@onready var EditorCamera := $"../../../../../../../EditorCamera"

func _on_swipe_toggled(toggled_on: bool) -> void:
	EditorCamera.swipe = toggled_on
