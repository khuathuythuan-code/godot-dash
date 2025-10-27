extends Node2D
class_name Level

const START_SPEED: Array[float] = [
	0.0,   # 0x
	0.807, # 0.5x
	1.0,   # 1x
	1.243, # 2x
	1.502, # 3x
	1.849, # 4x
	2.431, # 5x
]

@export_storage var version_history: UndoRedo

@export_file var song_path: String:
	set(value):
		register_required_song(song_path, value)
		song_path = value
		SongManager.load_song_threaded_request(value)
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start_time: float
@export var platformer: bool
@export var start_speed: int = 2
@export var start_reverse: bool
@export var start_gameplay_rotation_degrees: float
@export var color_channels: Array[ColorChannelData]
@export_storage var duration: float

@onready var song_player := AudioStreamPlayer.new()

var stopwatch: Stopwatch
var camera_rect: Rect2
var music_scale: float = 1.0
var required_songs: Dictionary[String, int] # HashMap<SongPath, SongUsers>
var required_fonts: Dictionary[String, int] # HashMap<FontPath, FontUsers>

var _pause_manager: Node


func _ready() -> void:
	if version_history == null:
		version_history = UndoRedo.new()
	_pause_manager = LevelManager.pause_manager
	stopwatch = Stopwatch.new()
	add_child(stopwatch, false, INTERNAL_MODE_FRONT)
	SongManager.load_song_threaded_request(song_path)
	song_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	song_player.set_bus("Music")
	LevelManager.level_song_player = song_player
	if LevelManager.current_level_duration != INF and duration != LevelManager.current_level_duration:
		duration = LevelManager.current_level_duration
	add_child(song_player, false, INTERNAL_MODE_FRONT)
	setup_color_channel_watchers()


func _process(_delta: float) -> void:
	music_scale = 0.85 + MusicVolume.get_volume()


func start_level() -> void:
	if get_tree().paused:
		await _pause_manager.unpaused
	song_player.stream = SongManager.load_song_threaded_get(song_path)
	song_player.play(song_start_time)
	LevelManager.platformer = platformer
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


func _set_object_color_channel_data(object: Node2D, object_data: Dictionary) -> void:
	if object.has_node(^"Base"):
		object_data.color_channels.base = BaseDetailHandler.use_hsv_watcher(object.get_node(^"Base")).get_groups().front()
		if not object_data.color_channels.base:
			object_data.color_channels.erase("base")
	else:
		# Color channel groups might be attached to the object directly
		# if it doesn't have a Base.
		var object_color_channels: Array = (
				BaseDetailHandler.use_hsv_watcher(object)
				.get_groups()
				.filter(func(group: String): return group.begins_with(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
		)
		if not object_color_channels.is_empty():
			object_data.color_channels = object_color_channels.front()
		# If the object doesn't have a Base, it can't have a Detail either.
		return
	if object.has_node(^"Detail"):
		object_data.color_channels.detail = BaseDetailHandler.use_hsv_watcher(object.get_node(^"Detail")).get_groups().front()
		if not object_data.color_channels.detail:
			object_data.color_channels.erase("detail")


func to_json() -> String:
	var data: Dictionary = {
		"name": name,
		"song_path": song_path,
		"start_speed": start_speed,
		"start_reverse": start_reverse,
		"start_gameplay_rotation_degrees": start_gameplay_rotation_degrees,
		"color_channels": color_channels.map(ColorChannelData.serialize),
		"duration": duration,
		"objects": [],
	}
	for object in get_children():
		if object is not Node2D:
			continue
		var object_data: Dictionary = {
			"name": object.name,
			"scene_file_path": object.scene_file_path.trim_prefix("res://"),
			"global_transform": object.global_transform,
			"groups": object.get_groups(),
			"color_channels": {},
			"hsv": object.get_node(^"HSVWatcher").serialize(),
		}
		_set_object_color_channel_data(object, object_data)
		if object.has_meta(&"texture_override"):
			object_data.texture_override = object.get_meta(&"texture_override")
		if object.has_meta(&"attributes"):
			object_data.attributes = object.get_meta(&"attributes")
		if object is Interactable:
			object_data.components = object.serialize_components()
			object_data.markers = object.serialize_markers()
		data.objects.append(object_data)
	# TODO: remove the indent character (only there for debugging)
	return JSON.stringify(data, "\t")


static func from_json(data: Dictionary) -> Level:
	var level := Level.new()
	level.name = data.name
	level.song_path = data.song_path
	level.start_speed = data.start_speed
	level.start_reverse = data.start_reverse
	level.start_gameplay_rotation_degrees = data.start_gameplay_rotation_degrees
	level.color_channels = data.color_channels
	level.duration = data.duration
	for object_data: Dictionary in data.objects:
		print(object_data.name)
	return level
