class_name GameScene
extends Node2D

@export var checkpoint_parent: Node2D
@export var pause_menu: StatisticsPauseMenu
@export var fade_screen: FadeScreen

var cached_level_data: Dictionary
var cached_level_path: String
var progress_percentage: float

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
	if not SceneManager.in_editor():
		LevelManager.player.process_mode = Node.PROCESS_MODE_DISABLED
		pause_menu.leave.connect(_leave_level)
		fade_screen.anticipate_fade_out()
		$EditorGridParallax/EditorGrid.hide()
		load_level()
		start_level()

func _process(delta: float) -> void:
	progress_percentage = $PercentageLayer.percentage

func load_level() -> void:
	var should_use_practice_snapshot: bool = not LevelManager.practice_level_snapshots.is_empty()
	assert(not LevelManager.current_level_path.is_empty() or should_use_practice_snapshot)
	if not should_use_practice_snapshot:
		for checkpoint in checkpoint_parent.get_children():
			checkpoint.queue_free()
	if LevelManager.current_level_path != cached_level_path:
		cached_level_path = LevelManager.current_level_path
		LevelManager.current_level_duration = INF # ← reset khi load level mới, tránh lặp giá trị cũ nhằm mục đích lưu duration trong editor
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
		cached_level_data = json.data
	var level: Level = Level.from_data(cached_level_data if not should_use_practice_snapshot else LevelManager.practice_level_snapshots[-1])
	if not SceneManager.in_editor():
		SceneManager.set_current_scene(SceneManager.Scene.LEVEL)
	add_loaded_level(level)


func add_loaded_level(level: Level) -> Level:
	LevelManager.current_level = level
	$Level.add_child(level, true)
	return level


func start_level() -> void:
	$PercentageLayer.show() 
	var level: Level = LevelManager.current_level
	level.prepare_external_data()
	LevelManager.player_camera.snap_view()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), false)
	if LevelManager.attempt == 0 and not Editor.in_editor:
		$FadeScreen.fade_out()
		await $FadeScreen.fade_finished
	level.start_level()
	LevelManager.attempt += 1
	LevelManager.player.process_mode = Node.PROCESS_MODE_INHERIT


func restart_level() -> void:
	var should_use_practice_snapshot: bool = not LevelManager.practice_level_snapshots.is_empty()
	if Editor.in_editor and not should_use_practice_snapshot:
		Editor.root.stop_playtest()
	else:
		free_current_level()
		reset()
		load_level()
		if not LevelManager.current_level.is_node_ready():
			await LevelManager.current_level.ready
		start_level()


func free_current_level() -> void:
	LevelManager.current_level.name = "%s_Level_%s" % [Constants.FREED, hash(LevelManager.current_level)]
	LevelManager.current_level.queue_free()


func reset() -> void:
	Engine.time_scale = 1.0
	LevelManager.ground_up.hide()
	LevelManager.ground_up.position.y = GroundMoverComponent.DEFAULT_GROUND_UP_Y
	LevelManager.ground_down.position.y = GroundMoverComponent.DEFAULT_GROUND_DOWN_Y
	LevelManager.player_duals.map(NodeUtils.free_node)
	LevelManager.player_duals.clear()
	LevelManager.player.reset()
	LevelManager.player_camera.reset()


func _leave_level() -> void:
	for level in $Level.get_children():
		level.stop_level()
	LevelManager.player.process_mode = Node.PROCESS_MODE_DISABLED
	LevelManager.player_camera.process_mode = Node.PROCESS_MODE_DISABLED
	$FadeScreen.fade_in()


static func get_camera_rect(camera: Camera2D, viewport: Viewport) -> Rect2:
	var rect_pos := camera.get_screen_center_position()
	var rect_size := (viewport.get_visible_rect().size / camera.zoom)
	return Rect2(rect_pos - rect_size * 0.5, rect_size)
