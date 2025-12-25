extends Node2D

class_name GameScene

func _ready() -> void:
	Engine.time_scale = 1
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
	ResourceLoader.load_threaded_request(LevelManager.current_level_path, "PackedScene", false, ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	var current_level: Level = ResourceLoader.load_threaded_get(LevelManager.current_level_path).instantiate()
	SceneManager.set_current_scene(SceneManager.Scene.LEVEL)
	add_loaded_level(current_level)


func add_loaded_level(level: Level) -> Level:
	LevelManager.current_level = level
	$Level.add_child(level)
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


func reset_level() -> void:
	LevelManager.ground_up.hide()
	LevelManager.ground_up.position.y = GroundMoverComponent.DEFAULT_GROUND_UP_Y
	LevelManager.ground_down.position.y = GroundMoverComponent.DEFAULT_GROUND_DOWN_Y
	# Avoid multiple scene transitions
	LevelManager.player.queue_free()
	LevelManager.player_duals.map(NodeUtils.free_node)
	LevelManager.player_duals.clear()
	LevelManager.current_level.queue_free()
	await get_tree().process_frame
	load_level()
	var new_player: Player = AssetManager.player_packed.instantiate()
	add_child(new_player)
	LevelManager.player_camera.player = new_player
	LevelManager.player_camera.center_on_player_at_0x_speed = true
	LevelManager.player_camera.static_factor = Vector2.ZERO
	LevelManager.player_camera.zoom = PlayerCamera.DEFAULT_ZOOM
	LevelManager.player_camera.offset = PlayerCamera.DEFAULT_OFFSET


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
