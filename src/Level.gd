extends Node2D
class_name Level

@warning_ignore("unused_signal")
signal default_font_changed

const START_SPEED: Array[float] = [
	0.0,   # 0x
	0.807, # 0.5x
	1.0,   # 1x
	1.243, # 2x
	1.502, # 3x
	1.849, # 4x
	2.431, # 5x
]

@export_file var song_path: String:
	set(value):
		register_required_song(song_path, value)
		song_path = value
		AssetManager.load_song_threaded_request(value)
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start_time: float
@export var default_font: String:
	set(value):
		register_required_font(default_font, value)
		default_font = value
		default_font_changed.emit()
@export var platformer: bool
@export var start_internal_gamemode: Player.Gamemode:
	set(value):
		start_internal_gamemode = value
		if LevelManager.player:
			LevelManager.player.internal_gamemode = start_internal_gamemode
@export var start_displayed_gamemode: Player.Gamemode:
	set(value):
		start_displayed_gamemode = value
		if LevelManager.player:
			LevelManager.player.displayed_gamemode = start_displayed_gamemode
			LevelManager.player.scale = Vector2.ONE if start_displayed_gamemode != Player.Gamemode.WAVE else Vector2.ONE * Player.PLAYER_SCALE_WAVE
@export var start_freefly: bool = true
@export var start_speed: int = 2
@export var start_reverse: bool
@export var start_gameplay_rotation_degrees: float
@export var default_background_color: Color = Constants.DEFAULT_BACKGROUND_COLOR:
	set(new_color):
		default_background_color = new_color
		background_color = new_color
@export var default_ground_color: Color = Constants.DEFAULT_GROUND_COLOR:
	set(new_color):
		default_ground_color = new_color
		ground_color = new_color
@export var default_line_color: Color = Constants.DEFAULT_LINE_COLOR:
	set(new_color):
		default_line_color = new_color
		line_color = new_color

@export_storage var color_channels: Array[ColorChannelData]
@export_storage var duration: float

@onready var song_player := AudioStreamPlayer.new()

var stopwatch: Stopwatch
var camera_rect: Rect2
var music_scale: float = 1.0
var required_songs: Dictionary[String, int] # HashMap<SongPath, SongUsers>
var required_fonts: Dictionary[String, int] # HashMap<FontPath, FontUsers>
var background_color: Color = Constants.DEFAULT_BACKGROUND_COLOR:
	set(new_color):
		background_color = new_color
		for background_sprite: Sprite2D in LevelManager.background_sprites:
			background_sprite.modulate = new_color
var ground_color: Color = Constants.DEFAULT_GROUND_COLOR:
	set(new_color):
		var ground_down: Sprite2D = LevelManager.ground_down.get_node("Ground")
		var ground_up: Sprite2D = LevelManager.ground_up.get_node("Ground")
		ground_down.self_modulate = new_color
		ground_up.self_modulate = new_color
var line_color: Color = Constants.DEFAULT_LINE_COLOR:
	set(new_color):
		# The material resource is shared between ground sprites
		var ground: Sprite2D = LevelManager.ground_down.get_node("Ground")
		ground.material.set_shader_parameter(&"ground_color", new_color)

var deleted_objects: Array[Node2D]
var _pause_manager: Node


func _ready() -> void:
	_pause_manager = LevelManager.pause_manager
	stopwatch = Stopwatch.new()
	add_child(stopwatch, false, INTERNAL_MODE_FRONT)
	AssetManager.load_song_threaded_request(song_path)
	song_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	song_player.set_bus("Music")
	LevelManager.level_song_player = song_player
	if LevelManager.current_level_duration != INF and duration != LevelManager.current_level_duration:
		duration = LevelManager.current_level_duration
	add_child(song_player, false, INTERNAL_MODE_FRONT)
	await ready
	setup_color_channel_watchers.call_deferred()


func _process(_delta: float) -> void:
	music_scale = 0.85 + MusicVolume.get_volume()


func start_level() -> void:
	if get_tree().paused:
		await _pause_manager.unpaused
	song_player.stream = AssetManager.load_song_threaded_get(song_path)
	song_player.play(song_start_time)
	LevelManager.platformer = platformer
	LevelManager.player.internal_gamemode = start_internal_gamemode
	LevelManager.player.displayed_gamemode = start_displayed_gamemode

	LevelManager.ground_up.show()
	if LevelManager.player_camera != null and get_viewport().get_camera_2d() == LevelManager.player_camera:
		LevelManager.player_camera.freefly = start_freefly
	if !start_freefly:
		GroundData.center = EditorScene.DEFAULT_PLAYER_POSITION
		GroundData.distance = GroundMoverComponent.LOCKEDFLY_GAMEMODE_GRID_HEIGHTS[start_internal_gamemode] * LevelManager.CELL_SIZE * 0.5
		if EditorScene.DEFAULT_PLAYER_POSITION.y + GroundData.distance > LevelManager.ground_down.DEFAULT_Y:
			GroundData.offset = (EditorScene.DEFAULT_PLAYER_POSITION.y + GroundData.distance) - LevelManager.ground_down.DEFAULT_Y
		else:
			GroundData.offset = 0

	LevelManager.player.scale = Vector2.ONE
	LevelManager.player.speed_multiplier = START_SPEED[start_speed]
	LevelManager.player.horizontal_direction = -1 if start_reverse else 1
	LevelManager.player.gameplay_rotation_degrees = start_gameplay_rotation_degrees
	LevelManager.player_camera.position = LevelManager.player.position
	LevelManager.level_playing = true
	stopwatch.paused = false


func stop_level() -> void:
	song_player.stop()
	LevelManager.player_duals.clear()
	LevelManager.level_playing = false
	process_mode = Node.PROCESS_MODE_DISABLED


func stop_timer() -> void:
	if Editor.in_editor:
		LevelManager.current_level_duration = stopwatch.get_elapsed_time_in_seconds()


func setup_color_channel_watchers() -> void:
	for color_channel in color_channels:
		var watcher := ColorChannelWatcher.new(color_channel)
		add_child(watcher)


func register_required_song(old_path: String, new_path: String) -> void:
	if required_songs.has(old_path):
		required_songs[old_path] -= 1
		if required_songs[old_path] <= 0:
			required_songs.erase(old_path)
	if not new_path.is_empty():
		if not required_songs.has(new_path):
			required_songs[new_path] = 0
		required_songs[new_path] += 1


func register_required_font(old_path: String, new_path: String) -> void:
	if required_fonts.has(old_path):
		required_fonts[old_path] -= 1
		if required_fonts[old_path] <= 0:
			required_fonts.erase(old_path)
	if not new_path.is_empty():
		if not required_fonts.has(new_path):
			required_fonts[new_path] = 0
		required_fonts[new_path] += 1


func to_data() -> Dictionary:
	var data: Dictionary = {
		"game_version": ProjectSettings.get_setting("application/config/version"),
		"name": name,
		"song_path": song_path,
		"song_start_time": song_start_time,
		"platformer": platformer,
		"start_internal_gamemode": start_internal_gamemode,
		"start_displayed_gamemode": start_displayed_gamemode,
		"start_freefly": start_freefly,
		"start_speed": start_speed,
		"start_reverse": start_reverse,
		"start_gameplay_rotation_degrees": start_gameplay_rotation_degrees,
		"default_background_color": default_background_color.to_rgba32(),
		"default_ground_color": default_ground_color.to_rgba32(),
		"default_line_color": default_line_color.to_rgba32(),
		"color_channels": color_channels.map(ColorChannelData.to_data),
		"duration": duration,
		"objects": [],
	}
	var objects: Array[Node2D]
	objects.assign(get_children())
	objects.append_array(deleted_objects)
	for object: Node2D in objects:
		var object_data: Dictionary = {
			"name": object.name,
			"scene_file_path": object.scene_file_path.trim_prefix("res://"),
			"transform": Serialize.Transform2D(object.transform),
			"groups": object.get_groups(),
			"color_channels": {},
			"hsv": object.get_node(^"HSVWatcher").to_data(),
			"z_index": object.z_index,
		}
		_set_object_color_channel_data(object, object_data)
		if object.has_meta(&"texture_override"):
			object_data.texture_override = object.get_meta(&"texture_override")
		if object.has_meta(&"attributes"):
			object_data.attributes = object.get_meta(&"attributes")
		if object is Interactable:
			object_data.components = object.components_to_data()
			object_data.markers = object.markers_to_data()
		if object in deleted_objects:
			object_data.deleted = true
		data.objects.append(object_data)
	return data


func _set_object_color_channel_data(object: Node2D, object_data: Dictionary) -> void:
	if object.has_node(^"Base"):
		var base_color_channel: Array[StringName] = BaseDetailHandler.use_hsv_watcher(object.get_node(^"Base")).get_groups()
		if not base_color_channel.is_empty():
			object_data.color_channels.base = base_color_channel[0]
	else:
		# Color channel groups might be attached to the object directly
		# if it doesn't have a Base.
		var object_color_channels: Array = (
				BaseDetailHandler.use_hsv_watcher(object)
				.get_groups()
				.filter(func(group: String): return group.begins_with(Constants.COLOR_CHANNEL_GROUP_PREFIX))
		)
		if not object_color_channels.is_empty():
			object_data.color_channels = object_color_channels.front()
		# If the object doesn't have a Base, it can't have a Detail either.
		return
	if object.has_node(^"Detail"):
		var detail_color_channel: Array[StringName] = BaseDetailHandler.use_hsv_watcher(object.get_node(^"Detail")).get_groups()
		if not detail_color_channel.is_empty():
			object_data.color_channels.detail = detail_color_channel[0]


static func from_data(data: Dictionary) -> Level:
	var level := Level.new()
	level.name = data.name
	level.song_path = data.song_path
	level.song_start_time = data.song_start_time
	level.platformer = data.platformer
	level.start_internal_gamemode = data.start_internal_gamemode
	level.start_displayed_gamemode = data.start_displayed_gamemode
	level.start_freefly = data.start_freefly
	level.start_speed = data.start_speed
	level.start_reverse = data.start_reverse
	level.start_gameplay_rotation_degrees = data.start_gameplay_rotation_degrees
	level.default_background_color = Color.hex(data.default_background_color)
	level.default_ground_color = Color.hex(data.default_ground_color)
	level.default_line_color = Color.hex(data.default_line_color)
	level.color_channels.assign(data.color_channels.map(ColorChannelData.from_data))
	level.duration = data.duration
	var resource_cache := ResourceCache.new()
	for object_data: Dictionary in data.objects:
		var prefab: PackedScene = resource_cache.get_or_load("res://%s" % object_data.scene_file_path)
		if prefab == null:
			push_error("Resource not found at path: res://%s" % object_data.scene_file_path)
			continue
		var object: Node2D = prefab.instantiate()
		object.name = object_data.name
		object.transform = Deserialize.Transform2D(object_data.transform)
		object.z_index = object_data.z_index
		# Deleted
		if object_data.has("deleted"):
			level.deleted_objects.append(object)
		else:
			level.add_child(object)
		# Groups
		for group: String in object_data.groups:
			object.add_to_group(group)
		# Color channels
		var base: Node2D = object.get_node_or_null(^"Base")
		var detail: Node2D = object.get_node_or_null(^"Detail")
		PlaceHandler.add_hsv_watchers(object, level)
		if object_data.color_channels is String or object_data.color_channels is StringName:
			BaseDetailHandler.use_hsv_watcher(object).add_to_group(object_data.color_channels)
		elif object_data.color_channels is Dictionary and not object_data.color_channels.is_empty():
			if object_data.color_channels.has("base"):
				BaseDetailHandler.use_hsv_watcher(base).add_to_group(object_data.color_channels.base)
			if object_data.color_channels.has("detail"):
				BaseDetailHandler.use_hsv_watcher(detail).add_to_group(object_data.color_channels.detail)
		# HSV
		object.get_node(^"HSVWatcher").use_data(object_data.hsv)
		# Texture Override
		if object_data.has("texture_override"):
			var override_data: Dictionary = object_data.texture_override
			if override_data.has("base"):
				base.texture = resource_cache.get_or_load("res://%s" % override_data.base)
			if override_data.has("detail"):
				detail.texture = resource_cache.get_or_load("res://%s" % override_data.detail)
			object.get_node(^"EditorSelectionCollider").id = override_data.id
			object.set_meta(&"texture_override", override_data)
		# Attributes
		if object_data.has("attributes"):
			var attributes: Array[String]
			attributes.assign(object_data.attributes)
			for attribute: String in attributes:
				var attribute_script: Script = resource_cache.get_or_load("%s/%s" % [Attribute.ATTRIBUTE_PATH_ROOT, attribute])
				NodeUtils.get_node_or_add(object, str(attribute_script.get_global_name()), attribute_script, NodeUtils.SET_OWNER | NodeUtils.FORCE_READABLE_NAME)
		# Interactables
		if object is Interactable:
			if object_data.has("components"):
				var components: Dictionary[String, Dictionary]
				components.assign(object_data.components)
				object.use_component_data(components)
			if object_data.has("markers"):
				var markers: Array[String]
				markers.assign(object_data.markers)
				object.markers_from_data(markers)
	return level
