extends Control

signal paused
signal unpaused
signal leave

const TITLE_SCREEN: PackedScene = preload("res://scenes/TitleScreen.tscn")

func _ready() -> void:
	$"../SettingsLayer".visible = visible
	process_mode = Node.PROCESS_MODE_ALWAYS
	LevelManager.pause_manager = self

func _unhandled_input(event: InputEvent) -> void:
	if LevelManager.level_playing and event.is_action_pressed("restart_level"):
		_on_restart_pressed()
	if event.is_action_pressed("pause_level") and Editor.shortcut_blocker == null and not SceneTransition.is_transitioning:
		_on_continue_pressed()
	if event.is_action_pressed("hide_pause_menu"):
		visible = not visible

func _notification(what):
	if not is_inside_tree():
		return
	if LevelManager.level_playing and not get_tree().paused and what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_on_continue_pressed()

func _on_leave_pressed() -> void:
	get_tree().paused = false
	get_parent().hide()
	leave.emit()
	LevelManager.platformer = false
	LevelManager.level_playing = false
	LevelAssetManager.unload_all()
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelQuit.ogg")
	SceneTransition.is_transitioning = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	LevelManager.current_level.process_mode = Node.PROCESS_MODE_DISABLED
	# HACK: removing the delay gets the screen frozen on the last frame after pressing the button instead of fading to black
	await get_tree().create_timer(0.5).timeout
	LevelManager.game_scene = null
	Editor.editor_clipboard.clear()
	SceneTransition.is_transitioning = false
	get_tree().change_scene_to_packed(TITLE_SCREEN)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)

func _on_continue_pressed() -> void:
	$VBoxContainer/LevelName.text = LevelManager.current_level.name
	if $"../SettingsLayer/SettingsContainer".position.y == -$"../SettingsLayer/SettingsContainer".get_viewport_rect().size.y:
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			paused.emit()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_parent().show()
			$"../SettingsLayer".show()
		else:
			unpaused.emit()
			if Editor.in_editor:
				# Input.mouse_mode = Input.MOUSE_MODE_CONFINED
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
			get_parent().hide()
			$"../SettingsLayer".hide()

func _on_restart_pressed() -> void:
	LevelManager.player_duals.clear()
	get_tree().paused = false
	unpaused.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	get_parent().hide()
	get_tree().reload_current_scene()
