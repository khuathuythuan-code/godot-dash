extends Node2D

class_name GameScene

@export var checkpoint_parent: Node2D


func _ready() -> void:
	Engine.time_scale = 1.0
	LevelManager.game_scene = self
	LevelManager.background_sprites.clear()
	LevelManager.background_sprites.append($BackgroundParallax/Background)
	LevelManager.background_sprites.append($BackgroundParallax/Background2)
	LevelManager.ground_up = null
	LevelManager.ground_down = null
	LevelManager.level_playing = false
	LevelManager.ground_down = $GroundDownParallax/GroundDownOrigin
	LevelManager.ground_up = $GroundUpParallax/GroundUpOrigin
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
	if not SceneManager.in_editor():
		LevelManager.player.process_mode = Node.PROCESS_MODE_DISABLED
		$PauseMenuLayer/PauseMenu.leave.connect(_leave_level)
		if LevelManager.attempt == 0:
			$FadeScreenLayer/FadeScreen.show()
			$FadeScreenLayer/FadeScreen.modulate = Color("000000ff")
		$EditorGridParallax/EditorGrid.hide()
		load_level()
		start_level()
	await get_tree().create_timer(0.1).timeout


func load_level() -> void:
	var file := FileAccess.open(LevelManager.current_level_path, FileAccess.READ)
	var json_string: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		var error_message: String = "JSON Parse Error: %s in %s at line %s" % [json.get_error_message(), json_string, json.get_error_line()]
		push_error(error_message)
		return
	if json.data is not Dictionary:
		push_error("Unexpected data")
		return
	var level: Level = Level.from_data(json.data)
	SceneManager.set_current_scene(SceneManager.Scene.LEVEL)
	add_loaded_level(level)


func add_loaded_level(level: Level) -> Level:
	LevelManager.current_level = level
	$Level.add_child(level, true)
	return level


func start_level() -> void:
	$PlayerCamera.snap_view()
	if LevelManager.attempt == 0:
		await get_tree().create_timer(0.2).timeout
		$FadeScreenLayer/FadeScreen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_SINE)
		await $FadeScreenLayer/FadeScreen.fade_finished
	for level in $Level.get_children():
		level.start_level()
	LevelManager.attempt += 1
	LevelManager.player.process_mode = Node.PROCESS_MODE_INHERIT


func restart_level() -> void:
	LevelManager.player_duals.clear()
	if Editor.in_editor:
		Editor.root.stop_playtest()
	else:
		reset()
		load_level()
		start_level()


func reset() -> void:
	LevelManager.current_level.name = "__freed_Level_%s" % hash(LevelManager.current_level)
	LevelManager.current_level.queue_free()
	Engine.time_scale = 1.0
	LevelManager.ground_up.hide()
	LevelManager.ground_up.position.y = GroundMoverComponent.DEFAULT_GROUND_UP_Y
	LevelManager.ground_down.position.y = GroundMoverComponent.DEFAULT_GROUND_DOWN_Y
	# Avoid multiple scene transitions
	LevelManager.player.name = "__freed_Player"
	LevelManager.player.queue_free()
	LevelManager.player_duals.map(NodeUtils.free_node)
	LevelManager.player_duals.clear()
	LevelManager.player_camera.limit_left = -10000000
	LevelManager.player_camera.limit_top = -10000000
	LevelManager.player_camera.limit_right = 10000000
	LevelManager.player_camera.limit_bottom = 10000000
	var new_player: Player = AssetManager.player_packed.instantiate()
	add_child(new_player)
	var player_camera: PlayerCamera = LevelManager.player_camera
	player_camera.player = new_player
	player_camera.center_on_player_at_0x_speed = true
	player_camera.static_factor = Vector2.ZERO
	player_camera.gameplay_offset_factor = Vector2.ONE
	player_camera.zoom = PlayerCamera.DEFAULT_ZOOM
	player_camera.offset = PlayerCamera.DEFAULT_OFFSET


func _leave_level() -> void:
	for level in $Level.get_children():
		level.stop_level()
	LevelManager.player.process_mode = Node.PROCESS_MODE_DISABLED
	LevelManager.player_camera.process_mode = Node.PROCESS_MODE_DISABLED
	$FadeScreenLayer/FadeScreen.fade_in(0.5, Tween.EASE_IN, Tween.TRANS_SINE)


static func get_camera_rect(camera: Camera2D, viewport: Viewport) -> Rect2:
	var rect_pos := camera.get_screen_center_position()
	var rect_size := (viewport.get_visible_rect().size / camera.zoom)
	return Rect2(rect_pos - rect_size * 0.5, rect_size)
