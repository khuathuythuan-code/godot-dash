extends CenterContainer
class_name EditorManual

func _on_close_pressed() -> void:
	Editor.shortcut_blocker = null
	hide()
