extends Control

signal paused
signal unpaused
signal leave
signal unsuspended
signal practice_mode_toggled(toggled_on: bool)

@export var settings_panel: TitleScreenPanel

var suspended: bool
var tween: Tween
var settings_were_open: bool


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	LevelManager.pause_manager = self
	settings_panel.get_node("MarginContainer/SettingsMenu").closed.connect(_on_settings_pressed)
	update_buttons_visibility.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if LevelManager.level_playing and event.is_action_pressed("restart_level"):
		_on_restart_pressed()
	if event.is_action_pressed("pause_level") and Editor.shortcut_blocker == null and not SceneManager.is_transitioning:
		_on_continue_pressed()
	if event.is_action_pressed("hide_pause_menu"):
		if visible:
			hide_tween()
		else:
			show_tween()


func _notification(what):
	if not is_inside_tree():
		return
	if LevelManager.level_playing and not get_tree().paused and what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_on_continue_pressed()


func update_buttons_visibility() -> void:
	%Restart.visible = not Editor.in_editor
	%Practice.visible = not Editor.in_editor
	%Edit.visible = not Editor.in_editor and LevelManager.current_level and LevelManager.current_level.is_editable


func unsuspend() -> void:
	suspended = false
	unsuspended.emit()


func _on_leave_pressed() -> void:
	get_tree().paused = false
	leave.emit()
	if suspended:
		await unsuspended
	settings_panel.hide_tween()
	hide_tween()
	LevelManager.platformer = false
	LevelManager.level_playing = false
	AssetManager.unload_all()
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelQuit.ogg")
	SceneManager.is_transitioning = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	LevelManager.current_level.process_mode = Node.PROCESS_MODE_DISABLED
	# HACK: removing the delay gets the screen frozen on the last frame after pressing the button instead of fading to black
	await get_tree().create_timer(0.5).timeout
	LevelManager.game_scene = null
	if Editor.clipboard:
		Editor.clipboard.clear()
	SceneManager.is_transitioning = false
	get_tree().change_scene_to_packed(AssetManager.title_screen_packed)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)


func _on_continue_pressed() -> void:
	$VBoxContainer/LevelName.text = LevelManager.current_level.name
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		paused.emit()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if settings_were_open:
			settings_panel.show_tween()
		show_tween()
	else:
		unpaused.emit()
		if Editor.in_editor:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		settings_were_open = settings_panel.visible
		if settings_panel.visible:
			settings_panel.hide_tween()
		hide_tween()


func show_tween() -> void:
	get_parent().show()
	show()
	if tween:
		tween.stop()
	tween = create_tween()
	tween.tween_property(self, "position:x", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT).from(-size.x)
	await tween.finished


func hide_tween() -> void:
	if tween:
		tween.stop()
	tween = create_tween()
	tween.tween_property(self, "position:x", -size.x, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	await tween.finished
	hide()
	get_parent().hide()


func _on_restart_pressed() -> void:
	LevelManager.player_duals.clear()
	get_tree().paused = false
	unpaused.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	get_parent().hide()
	get_tree().reload_current_scene()


func _on_edit_pressed() -> void:
	var file := FileAccess.open(LevelManager.current_level_path, FileAccess.READ)
	var json_string: String = file.get_as_text()
	file.close()
	Editor.level_data_snapshot = JSON.parse_string(json_string)
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Creating a level")
		DiscordRPCHandler.refresh()
	get_tree().paused = false
	get_tree().change_scene_to_packed(AssetManager.editor_packed)


func _on_settings_pressed() -> void:
	if settings_panel.visible:
		settings_panel.hide_tween()
		return
	settings_panel.show_tween()


func _on_practice_toggled(toggled_on: bool) -> void:
	LevelManager.practice_mode = toggled_on
	# Forward the signal to toggle the visibility of the touchscreen practice UI in GameScene
	practice_mode_toggled.emit(toggled_on)
	_on_continue_pressed()
