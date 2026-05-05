class_name Level
extends Node2D

@warning_ignore("unused_signal")
signal default_font_changed

enum SerializeReason {
	SAVE,
	PRACTICE_ATTEMPT,
}

enum EnterEffect {
	DISABLED,
	FADE,
	FADE_AND_MOVE_DOWN,
}

const START_SPEED: Array[float] = [
	0.0, # 0x
	0.807, # 0.5x
	1.0, # 1x
	1.243, # 2x
	1.502, # 3x
	1.849, # 4x
	2.431, # 5x
]

@export var creator: String = Config.username
@export var description: String = ""
@export var rating: int = -1
@export var creation_date: int = int(Time.get_unix_time_from_system())
@export var flashing_lights: bool = false

@export_file var song_path: String:
	set(value):
		register_required_song(song_path, value.get_file())
		song_path = value.get_file()
		AssetManager.load_song_threaded_request(Constants.SONG_DIR + value.get_file())
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start_time: float
@export var default_font: String:
	set(value):
		register_required_font(default_font, value)
		default_font = value
		default_font_changed.emit()
@export var platformer: bool:
	set(value):
		platformer = value
		LevelManager.platformer = value
		if LevelManager.player:
			LevelManager.player.displayed_gamemode = start_displayed_gamemode
@export var start_position: Vector2 = Constants.DEFAULT_PLAYER_POSITION
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
			LevelManager.player.update_player_scale(false)
@export var start_freefly: bool = true
@export var start_speed_preset: int = EasedSpeedChangerComponent.SpeedPreset.x1
@export var start_speed: float = START_SPEED[2]
@export var start_reverse: bool
@export var start_gameplay_rotation_degrees: float
@export var start_gravity_multiplier: float = 1.0
@export var start_gravity_flip: int = 1
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
@export var enter_effect: EnterEffect = EnterEffect.FADE:
	set(new_enter_effect):
		enter_effect = new_enter_effect
		var _new_enter_effect: EnterEffect = new_enter_effect
		if Editor.render_mode_manager and Editor.render_mode_manager.mode != RenderMode.Mode.RENDERED_MODE:
			_new_enter_effect = EnterEffect.DISABLED
		if not AssetManager.ready:
			await AssetManager.ready
		if not AssetManager.fade_enter_effect:
			await AssetManager.fade_enter_loaded
		AssetManager.fade_enter_effect.set_shader_parameter(&"mode", _new_enter_effect)
		if not AssetManager.fade_enter_effect_canvas_group:
			await AssetManager.fade_enter_canvas_group_loaded
		AssetManager.fade_enter_effect_canvas_group.set_shader_parameter(&"mode", _new_enter_effect)
# Used to disable "Edit" button in the pause menu for official levels
@export var is_editable: bool = true

@export_storage var color_channels: Array[ColorChannelData]
@export_storage var duration: float

var song_player: AudioStreamPlayer
var stopwatch: Stopwatch
var layers: Array[Layer]
var active_layer_idx: int
var camera_rect: Rect2
var music_scale: float = 1.0
var required_songs: Dictionary[String, int] # HashMap<SongPath, SongUsers>
var required_fonts: Dictionary[String, int] # HashMap<FontPath, FontUsers>
var background_color: Color = Constants.DEFAULT_BACKGROUND_COLOR:
	set(new_color):
		if Editor.render_mode_manager and Editor.render_mode_manager.mode == RenderMode.Mode.OBJECT_MODE:
			return
		background_color = new_color
		for background_sprite: Sprite2D in LevelManager.background_sprites:
			background_sprite.modulate = new_color
var ground_color: Color = Constants.DEFAULT_GROUND_COLOR:
	set(new_color):
		if Editor.render_mode_manager and Editor.render_mode_manager.mode == RenderMode.Mode.OBJECT_MODE:
			return
		var ground_down: Sprite2D = LevelManager.ground_down.get_node(^"Ground")
		var ground_up: Sprite2D = LevelManager.ground_up.get_node(^"Ground")
		ground_down.self_modulate = new_color
		ground_up.self_modulate = new_color
var line_color: Color = Constants.DEFAULT_LINE_COLOR:
	set(new_color):
		if Editor.render_mode_manager and Editor.render_mode_manager.mode == RenderMode.Mode.OBJECT_MODE:
			return
		# The material resource is shared between ground sprites
		var ground: Sprite2D = LevelManager.ground_down.get_node(^"Ground")
		ground.material.set_shader_parameter(&"ground_color", new_color)


func _ready() -> void:
	if layers.is_empty():
		var new_layer: Layer = Layer.new()
		new_layer.name = "Unnamed Layer"
		layers.append(new_layer)
		add_child(new_layer)
		if Editor.in_editor:
			active_layer_idx = 0
	stopwatch = Stopwatch.new()
	stopwatch.name = "Stopwatch"
	stopwatch.paused = true
	add_child(stopwatch, false, INTERNAL_MODE_BACK)
	AssetManager.load_song_threaded_request(song_path)
	song_player = AudioStreamPlayer.new()
	song_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	song_player.set_bus(&"Music")
	song_player.name = "Song Player"
	LevelManager.song_player = song_player
	if LevelManager.current_level_duration != INF and duration != LevelManager.current_level_duration:
		duration = LevelManager.current_level_duration
		#Điều kiện này được thiết kế cho cùng 1 level restart — dùng current_level_duration 
		#để restore sau khi clear. Nhưng khi chuyển sang level khác, nó lại ghi đè duration
		 #của level mới bằng duration của level cũ.
	add_child(song_player, false, INTERNAL_MODE_BACK)


func _process(_delta: float) -> void:
	music_scale = 0.85 + MusicVolume.get_volume()


func prepare_external_data() -> void:
	song_player.stream = AssetManager.load_song_threaded_get(Constants.SONG_DIR + song_path)
	LevelManager.platformer = platformer
	LevelManager.player.internal_gamemode = start_internal_gamemode
	LevelManager.player.displayed_gamemode = start_displayed_gamemode
	LevelManager.player.global_position = start_position
	LevelManager.player.last_automatic_checkpoint_position = start_position
	if platformer:
		LevelManager.touchscreen_controls.enable_platformer(start_internal_gamemode == Player.Gamemode.WAVE)
	else:
		LevelManager.touchscreen_controls.disable_platformer()

	LevelManager.ground_up.show()
	if LevelManager.player_camera and get_viewport().get_camera_2d() == LevelManager.player_camera:
		LevelManager.player_camera.freefly = start_freefly
	if not start_freefly:
		GroundData.center = Constants.DEFAULT_PLAYER_POSITION
		GroundData.distance = GroundMoverComponent.LOCKEDFLY_GAMEMODE_GRID_HEIGHTS[start_internal_gamemode] * Constants.CELL_SIZE * 0.5
		if Constants.DEFAULT_PLAYER_POSITION.y + GroundData.distance > LevelManager.ground_down.default_y:
			GroundData.offset = (Constants.DEFAULT_PLAYER_POSITION.y + GroundData.distance) - LevelManager.ground_down.default_y
		else:
			GroundData.offset = 0

	LevelManager.player.speed_multiplier = start_speed
	LevelManager.player.horizontal_direction = -1 if start_reverse else 1
	LevelManager.player.gameplay_rotation_degrees = start_gameplay_rotation_degrees
	LevelManager.player.gravity_multiplier = start_gravity_multiplier
	LevelManager.player.gravity_flip = start_gravity_flip
	LevelManager.player_camera.position = LevelManager.player.position


func create_layer(layer_name: String) -> Layer:
	var new_layer: Layer = Layer.new()
	new_layer.name = layer_name

	var add_layer_to_tree := func():
		add_child(new_layer, true)
		layers.append(new_layer)
		new_layer.owner = self
		if Editor.in_editor:
			Editor.root.inspector_tree.refresh()
	var remove_layer_from_tree := func():
		layers.erase(new_layer)
		remove_child(new_layer)
		if Editor.in_editor:
			Editor.root.inspector_tree.refresh()

	Editor.version_history.create_action("Created layer " + layer_name)
	Editor.version_history.add_do_method(add_layer_to_tree)
	Editor.version_history.add_undo_method(remove_layer_from_tree)
	Editor.version_history.commit_action()

	return new_layer


func remove_layer(layer_name: String) -> bool:
	var layer: Layer = get_node_or_null(layer_name)
	if not layer:
		return false
	layer.queue_free()
	return true


func move_layer(layer_name: String, new_layer_index: int) -> void:
	var layer: Layer = get_node_or_null(layer_name)
	if not layer:
		return
	layers.remove_at(layer.get_index())
	layers.insert(new_layer_index, layer)
	move_child(layer, new_layer_index)


func start_level() -> void:
	if get_tree().paused:
		#await LevelManager.pause_menu.unpaused
		await LevelManager.stat_pause_menu.unpaused
	song_player.play(song_start_time)
	stopwatch.reset()
	stopwatch.paused = false
	LevelManager.level_playing = true


func stop_level() -> void:
	song_player.stop()
	LevelManager.player_duals.clear()
	LevelManager.level_playing = false
	process_mode = Node.PROCESS_MODE_DISABLED


func stop_timer() -> void:
	if not Editor.in_editor:
		return
	LevelManager.current_level_duration = stopwatch.get_elapsed_time_in_seconds()

	

func setup_color_channel_watchers() -> void:
	for color_channel: ColorChannelData in color_channels:
		var watcher := ColorChannelWatcher.new(color_channel)
		watcher.name = "Watcher@%s" % color_channel.associated_group.trim_prefix(Constants.COLOR_CHANNEL_GROUP_PREFIX)
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


func to_data(reason: SerializeReason = SerializeReason.SAVE) -> Dictionary:
	var practice := func(practice_off: Variant, practice_on: Variant): return practice_on if reason == SerializeReason.PRACTICE_ATTEMPT else practice_off
	var player: Player = LevelManager.player
	var data: Dictionary = {
		"game_version": ProjectSettings.get_setting("application/config/version"),
		"name": name,
		"creator": creator,
		"description": description,
		"creation_date": creation_date,
		"rating": rating,
		"flashing_lights": flashing_lights,
		"is_editable": is_editable,
		"song_path": practice.call(song_path, song_player.stream.resource_path if song_player.stream else song_path),
		"song_start_time": practice.call(song_start_time, song_player.get_playback_position()),
		"platformer": platformer,
		"start_position": Serialize.Vector2(player.global_position),
		"start_internal_gamemode": practice.call(start_internal_gamemode, player.internal_gamemode),
		"start_displayed_gamemode": practice.call(start_displayed_gamemode, player.displayed_gamemode),
		"start_freefly": practice.call(start_freefly, LevelManager.player_camera.freefly),
		"start_speed": practice.call(start_speed, player.speed_multiplier),
		"start_speed_preset": start_speed_preset,
		"start_reverse": practice.call(start_reverse, player.horizontal_direction < 0),
		"start_gameplay_rotation_degrees": practice.call(start_gameplay_rotation_degrees, player.gameplay_rotation_degrees),
		"start_gravity_multiplier": practice.call(start_gravity_multiplier, player.gravity_multiplier),
		"start_gravity_flip": practice.call(start_gravity_flip, player.gravity_flip),
		"default_background_color": default_background_color.to_rgba32(),
		"default_ground_color": default_ground_color.to_rgba32(),
		"default_line_color": default_line_color.to_rgba32(),
		"enter_effect": enter_effect,
		"color_channels": color_channels.map(ColorChannelData.to_data),
		"duration": duration,
		"layers": [],
		"active_layer_idx": active_layer_idx,
		"player_data": {
			"groups": player.get_groups(),
			"hsv": player.get_node(^"HSVWatcher").to_data(),
			"z_index": player.z_index,
		},
	}
	if reason == SerializeReason.PRACTICE_ATTEMPT:
		data.practice_data = _get_practice_data()
	for layer: Layer in layers:
		var layer_data: Dictionary = {
			"name": layer.name,
			"objects": [],
		}
		var objects: Array[Node2D]
		objects.assign(layer.get_children().filter(func(node: Node): return node is Node2D))
		for object: Node2D in objects:
			layer_data.objects.append(_serialize_object(object, reason))
		data.layers.append(layer_data)
	return data


func _serialize_object(object: Node2D, reason: SerializeReason) -> Dictionary:
	var object_data: Dictionary = {
		"name": object.name,
		"scene_file_path": object.scene_file_path.trim_prefix("res://"),
		"transform": Serialize.Transform2D(object.transform),
		"groups": object.get_groups(),
		"color_channels": { },
		"hsv": object.get_node(^"HSVWatcher").to_data(),
		"children_hsv": [],
		"z_index": object.z_index,
	}
	_set_object_color_channel_data(object, object_data)
	if object.has_meta(Constants.TEXTURE_OVERRIDE_META):
		object_data.texture_override = object.get_meta(Constants.TEXTURE_OVERRIDE_META)
	if object.has_meta(&"attributes"):
		object_data.attributes = object.get_meta(&"attributes")
	if object.has_meta(&"physics"):
		object_data.physics = NodeUtils.get_child_of_type(object, PhysicsObjectComponent).get_data()
	if object is Interactable:
		object_data.components = object.components_to_data(reason)
		object_data.markers = object.markers_to_data()
	for child in object.get_children():
		var hsv_watcher: HSVWatcher = NodeUtils.get_child_of_type(child, HSVWatcher)
		if hsv_watcher:
			object_data.children_hsv.append(hsv_watcher.to_data())
	return object_data


func _set_object_color_channel_data(object: Node2D, object_data: Dictionary) -> void:
	if object.has_node(^"Base"):
		var base_color_channel: Array[StringName] = BaseDetailHandler.use_hsv_watcher(object.get_node(^"Base")).get_groups()
		if not base_color_channel.is_empty():
			object_data.color_channels.base = base_color_channel[0]
	else:
		# Color channel groups might be attached to the object directly
		# if it doesn't have a Base.
		var object_color_channels: Array = (
			BaseDetailHandler.use_hsv_watcher(object).get_groups().filter(func(group: String): return group.begins_with(Constants.COLOR_CHANNEL_GROUP_PREFIX))
		)
		if not object_color_channels.is_empty():
			object_data.color_channels = object_color_channels.front()
		# If the object doesn't have a Base, it can't have a Detail either.
		return
	if object.has_node(^"Detail"):
		var detail_color_channel: Array[StringName] = BaseDetailHandler.use_hsv_watcher(object.get_node(^"Detail")).get_groups()
		if not detail_color_channel.is_empty():
			object_data.color_channels.detail = detail_color_channel[0]


func _get_practice_data() -> Dictionary:
	var practice_data: Dictionary = { }
	practice_data.player_velocity = LevelManager.player.velocity
	practice_data.replay = LevelManager.player.replay
	practice_data.physics_tick = LevelManager.player.replay_physics_tick
	return practice_data


static func from_data(data: Dictionary) -> Level:
	var level := Level.new()
	level.name = data.name
	level.creator = data.creator
	level.description = data.description
	level.rating = data.rating
	level.creation_date = data.creation_date
	level.flashing_lights = data.flashing_lights
	level.is_editable = data.is_editable
	level.song_path = data.song_path
	level.song_start_time = data.song_start_time
	level.platformer = data.platformer
	level.start_position = Deserialize.Vector2(data.start_position)
	level.start_internal_gamemode = data.start_internal_gamemode
	level.start_displayed_gamemode = data.start_displayed_gamemode
	level.start_freefly = data.start_freefly
	level.start_speed = data.start_speed
	level.start_speed_preset = data.start_speed_preset
	level.start_reverse = data.start_reverse
	level.start_gameplay_rotation_degrees = data.start_gameplay_rotation_degrees
	level.start_gravity_multiplier = data.start_gravity_multiplier
	level.start_gravity_flip = data.start_gravity_flip
	level.default_background_color = Color.hex(data.default_background_color)
	level.default_ground_color = Color.hex(data.default_ground_color)
	level.default_line_color = Color.hex(data.default_line_color)
	level.enter_effect = data.enter_effect
	level.color_channels.assign(data.color_channels.map(ColorChannelData.from_data))
	level.ready.connect(level.setup_color_channel_watchers, CONNECT_ONE_SHOT)
	level.duration = data.duration

	LevelManager.player.global_position = level.start_position
	for group in data.player_data.groups:
		LevelManager.player.add_to_group(group)
	LevelManager.player.get_node(^"HSVWatcher").use_data(data.player_data.hsv)
	LevelManager.player.z_index = data.player_data.z_index
	# start_internal_gamemode and start_displayed_gamemode are set on the player
	# in their respective setters.

	if "practice_data" in data:
		var practice_data: Dictionary = data.practice_data
		practice_data.replay.data = practice_data.replay.data.slice(0, practice_data.physics_tick)
		LevelManager.player.velocity = practice_data.player_velocity
		LevelManager.player.replay = practice_data.replay
		LevelManager.player.replay_physics_tick = practice_data.physics_tick

	var resource_cache := ResourceCache.new()
	for layer_data: Dictionary in data.layers:
		var layer: Layer = Layer.new()
		layer.name = layer_data.name
		for object_data: Dictionary in layer_data.objects:
			var object: Node2D = instantiate_object_from_data(object_data, resource_cache)
			layer.add_child(object)
			object.set_meta(Constants.LAYER_META, layer)
			deserialize_data_to_object(object_data, object, level, resource_cache)
		level.layers.append(layer)
		level.add_child(layer)
	level.active_layer_idx = data.active_layer_idx

	return level


static func instantiate_object_from_data(object_data: Dictionary, resource_cache: ResourceCache) -> Node2D:
	var prefab: PackedScene = resource_cache.get_or_load("res://%s" % object_data.scene_file_path)
	if not prefab:
		push_error("Resource not found at path: res://%s" % object_data.scene_file_path)
		return
	if Config.ldm and not Editor.in_editor and object_data.has("attributes"):
		if object_data.attributes.has("LDMAttribute.gd"):
			return
	var object: Node2D = prefab.instantiate()
	object.name = object_data.name
	object.transform = Deserialize.Transform2D(object_data.transform)
	object.z_index = object_data.z_index
	return object


static func deserialize_data_to_object(object_data: Dictionary, object: Node2D, level: Level, resource_cache: ResourceCache) -> void:
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
	for child in object.get_children():
		if object_data.children_hsv.size() == 0:
			break
		var hsv_watcher: HSVWatcher = NodeUtils.get_child_of_type(child, HSVWatcher)
		if hsv_watcher:
			hsv_watcher.use_data(object_data.children_hsv[0])
			object_data.children_hsv.remove_at(0)
	# Texture Override
	if "texture_override" in object_data:
		var override_data: Dictionary = object_data.texture_override
			# ❗ bỏ qua nếu rỗng
		if override_data.is_empty():
			return
		if "base" in override_data:
			base.texture = resource_cache.get_or_load("res://%s" % override_data.base)
		if "detail" in override_data:
			detail.texture = resource_cache.get_or_load("res://%s" % override_data.detail)
			
			
			# ❗ check id trước khi dùng
		if "id" in override_data:
			var collider = object.get_node_or_null(^"EditorSelectionCollider")
			if collider:
				collider.id = override_data.id
		object.set_meta(Constants.TEXTURE_OVERRIDE_META, override_data)
	# Attributes
	if "attributes" in object_data:
		var attributes: Array[String]
		attributes.assign(object_data.attributes)
		for attribute: String in attributes:
			var attribute_script: Script = resource_cache.get_or_load("%s/%s" % [Attribute.ATTRIBUTE_PATH_ROOT, attribute])
			NodeUtils.get_node_or_add(object, str(attribute_script.get_global_name()), attribute_script, NodeUtils.SET_OWNER | NodeUtils.FORCE_READABLE_NAME)
	# Physics
	if "physics" in object_data:
		NodeUtils.get_child_of_type(object, PhysicsObjectComponent).use_data(object_data.physics)
	# Interactables
	if object is Interactable:
		if "components" in object_data:
			var components: Dictionary[String, Dictionary]
			components.assign(object_data.components)
			object.use_component_data(components)
		if "markers" in object_data:
			var markers: Array[String]
			markers.assign(object_data.markers)
			object.markers_from_data(markers)
	# Enter Effect
	for child: Node in object.get_children():
		apply_enter_effect(child)


static func apply_enter_effect(object_child: Node) -> void:
	if object_child is CanvasGroup:
		object_child.material = AssetManager.fade_enter_effect_canvas_group
		return
	if not (
		object_child is Sprite2D
		or object_child is NinePatchSprite2D
		or object_child is ReboundOrbSprite
		or object_child is ReboundPadSprite
		or object_child is HitboxDisplay
		or object_child is Line2D
	):
		return
	if object_child.material:
		return
	object_child.material = AssetManager.fade_enter_effect
