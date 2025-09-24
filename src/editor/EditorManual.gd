extends CenterContainer
class_name EditorManual

func _on_close_pressed() -> void:
	LevelManager.shortcut_blocker = null
	hide()
