extends CanvasLayer
class_name LevelCompleteMenu

signal complete
signal leave
signal restart

@export var stat_controller: StatController

func _show() -> void:
	get_tree().paused = true
	if get_tree().paused:
		show()
		complete.emit()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_leave_pressed() -> void:
	get_tree().paused = false
	leave.emit()
	LevelManager.platformer = false
	LevelManager.level_playing = false
	AssetManager.unload_all()
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelQuit.ogg")
	SceneManager.is_transitioning = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), true)
	LevelManager.current_level.process_mode = Node.PROCESS_MODE_DISABLED
	await LevelManager.game_scene.fade_screen.fade_finished
	LevelManager.game_scene = null
	SceneManager.is_transitioning = false
	get_tree().change_scene_to_packed(AssetManager.title_screen_packed)
	AudioServer.set_bus_mute.call_deferred(AudioServer.get_bus_index(&"Music"), false)


func _on_restart_pressed() -> void:
	stat_controller.is_restart_after_complete = true
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Editor.in_editor else Input.MOUSE_MODE_CONFINED_HIDDEN
	restart.emit()
	hide()
	LevelManager.game_scene.restart_level()
	stat_controller.refresh()
