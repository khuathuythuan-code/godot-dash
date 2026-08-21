extends Node

signal fade_enter_loaded
signal fade_enter_canvas_group_loaded

var thread: Thread

var loaded_songs: Dictionary[String, AudioStream]
var loaded_fonts: Dictionary[String, Font]
var loaded_icons: Dictionary
#var loaded_icons: Dictionary[PreviewIcon.Icon, Dictionary]
var player_packed: PackedScene
var title_screen_packed: PackedScene
var editor_packed: PackedScene
var game_scene_packed: PackedScene
var menu_loop: AudioStream
var fade_enter_effect: ShaderMaterial
var fade_enter_effect_canvas_group: ShaderMaterial
var generated_editor_object_thumbnails: Dictionary[String, ImageTexture]


func _ready() -> void:
	#ResourceLoader.load_threaded_request("res://scenes/TitleScreen.tscn")
	ResourceLoader.load_threaded_request("res://scenes/TestMainMenu.tscn")
	ResourceLoader.load_threaded_request("res://scenes/EditorScene.tscn")
	ResourceLoader.load_threaded_request("res://scenes/GameScene.tscn")
	ResourceLoader.load_threaded_request("res://scenes/components/game_components/Player.tscn")
	ResourceLoader.load_threaded_request("res://resources/FadeEnterEffect.tres")
	ResourceLoader.load_threaded_request("res://resources/FadeEnterEffectCanvasGroup.tres")
	#title_screen_packed = ResourceLoader.load_threaded_get("res://scenes/TitleScreen.tscn")
	title_screen_packed = ResourceLoader.load_threaded_get("res://scenes/TestMainMenu.tscn")
	editor_packed = ResourceLoader.load_threaded_get("res://scenes/EditorScene.tscn")
	game_scene_packed = ResourceLoader.load_threaded_get("res://scenes/GameScene.tscn")
	player_packed = ResourceLoader.load_threaded_get("res://scenes/components/game_components/Player.tscn")
	fade_enter_effect = ResourceLoader.load_threaded_get("res://resources/FadeEnterEffect.tres")
	fade_enter_loaded.emit()
	fade_enter_effect_canvas_group = ResourceLoader.load_threaded_get("res://resources/FadeEnterEffectCanvasGroup.tres")
	fade_enter_canvas_group_loaded.emit()
	load_icons()


func load_song(path: String) -> AudioStream:
	if path.is_empty() or path.ends_with("/") or path == Constants.SONG_DIR or path == Constants.SONG_DIR.trim_suffix("/"):
		return null
	var audio_stream: AudioStream
	if path.begins_with("uid") or path.begins_with("res://"):
		audio_stream = load(path)
	else:
		match path.get_extension():
			"mp3":
				audio_stream = AudioStreamMP3.load_from_file(path)
			"wav":
				audio_stream = AudioStreamWAV.load_from_file(path)
			"ogg":
				audio_stream = AudioStreamOggVorbis.load_from_file(path)
			_:
				pass
				#printerr("Song isn't of valid type")
	loaded_songs[path] = audio_stream
	return audio_stream


func load_song_threaded_request(path: String) -> Error:
	if path in loaded_songs:
		return OK
	if path.is_empty() or path == null or path.ends_with("/") or path == Constants.SONG_DIR or path == Constants.SONG_DIR.trim_suffix("/"):
		return ERR_FILE_BAD_PATH
	# Web không hỗ trợ thread → load đồng bộ
	if OS.has_feature("web"):
		load_song(path)
		return OK
	if not thread:
		thread = Thread.new()
	if thread.is_started():
		thread.wait_to_finish()
	return thread.start(load_song.bind(path))


func load_song_threaded_get(path: String) -> AudioStream:
	if path.is_empty() or path == null or path.ends_with("/") or path == Constants.SONG_DIR or path == Constants.SONG_DIR.trim_suffix("/"):
		return null
	if thread and thread.is_started():  # thêm "thread and" để tránh null error
		thread.wait_to_finish()
	if not path in loaded_songs:  # nếu chưa load được
		load_song(path)           # load đồng bộ lần nữa
	if not path in loaded_songs:  # vẫn không có
		return null               # trả về null thay vì crash
	return loaded_songs[path]


func unload_all() -> void:
	loaded_songs.clear()
	loaded_fonts.clear()


func load_font(path: String) -> FontFile:
	if path in loaded_fonts:
		return loaded_fonts[path]
	var loaded_font: FontFile
	if path.is_empty():
		loaded_font = ThemeDB.get_project_theme().default_font.duplicate()
	else:
		if path.begins_with("res://") or path.begins_with("uid://"):
			var res = load(path)
			if res is FontFile:
				loaded_font = res
			elif res is Font:
				loaded_font = res
		else:
			loaded_font = FontFile.new()
			var error: Error = loaded_font.load_dynamic_font(path)
			if error != OK:
				push_error("Error while loading font at %s: %s" % [path, error])
				return null
	if loaded_font:
		loaded_font.multichannel_signed_distance_field = true
		loaded_font.msdf_pixel_range = 64
		loaded_font.msdf_size = 128
	loaded_fonts[path] = loaded_font
	return loaded_font


func load_image(path: String) -> Texture2D:
	if path.contains("res://"):
		return load(path)
	var image := Image.load_from_file(path)
	if image == null:
		if path.is_empty():
			path = "null"
		Toasts.error("texture not found at path: " + path)
		return load("res://assets/textures/guis/title_screen/placeholder.svg")
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func load_icon(path: String, icon: PreviewIcon.Icon) -> Texture2D:
	if path.contains(loaded_icons[icon]["path"]):
		match icon:
			PreviewIcon.Icon.SPIDER:
				if path.contains("Spider_Head.svg"):
					return loaded_icons[icon]["head_sprite"]
				if path.contains("Spider_Head-glow.svg"):
					return loaded_icons[icon]["head_glow"]
				if path.contains("Spider_Leg.svg"):
					return loaded_icons[icon]["leg_sprite"]
				if path.contains("Spider_Leg-glow.svg"):
					return loaded_icons[icon]["leg_glow"]
			PreviewIcon.Icon.DEATH_EFFECT:
				for frame in loaded_icons[icon]["sprite"]:
					if frame["path"] == path:
						#return frame["path"]
						return frame["sprite"]
			_:
				return loaded_icons[icon]["sprite"]
	return load_image(path)


func load_icons(icons: Array = PreviewIcon.Icon.values()) -> void:
	for icon in icons:
		var icon_path: String = Config.icons[icon]["path"]
		loaded_icons.get_or_add(icon, { })
		loaded_icons[icon]["path"] = icon_path
		match icon:
			PreviewIcon.Icon.SWING:
				loaded_icons[icon]["sprite"] = load_image(icon_path.path_join("Swing.svg"))
			#PreviewIcon.Icon.DEATH_EFFECT:
				#for frame in DirAccess.open(icon_path).get_files():
					#if frame.contains(".import"):
						#continue
					#loaded_icons[icon].get_or_add("sprite", []).append({ "sprite"= load_image(icon_path + "/" + frame), "path"= icon_path + "/" + frame })
			PreviewIcon.Icon.DEATH_EFFECT:
				loaded_icons[icon]["sprite"] = [] # Clear trước khi nạp lại
				var loaded_frames := []
				var dir_access := DirAccess.open(icon_path)
				if dir_access:
					for frame in dir_access.get_files():
						var clean_frame := frame.trim_suffix(".import").trim_suffix(".remap")
						var frame_path := icon_path.path_join(clean_frame)
						if not frame_path in loaded_frames:
							loaded_frames.append(frame_path)
							loaded_icons[icon]["sprite"].append({ "sprite"= load_image(frame_path), "path"= frame_path })
				# Dự phòng nạp frame trên Web
				if loaded_icons[icon]["sprite"].is_empty():
					for i in range(1, 100):
						var frame_name := "DeathEffect%02d.png" % i
						var frame_path := icon_path.path_join(frame_name)
						if ResourceLoader.exists(frame_path):
							loaded_icons[icon]["sprite"].append({ "sprite"= load_image(frame_path), "path"= frame_path })
						else:
							break
			PreviewIcon.Icon.SPIDER:
				loaded_icons[icon]["head_sprite"] = load_image(icon_path.path_join("Spider_Head2.png"))
				loaded_icons[icon]["head_glow"] = load_image(icon_path.path_join("Spider_Head-glow.svg"))
				loaded_icons[icon]["leg_sprite"] = load_image(icon_path.path_join("Spider_Leg2.png"))
				loaded_icons[icon]["leg_glow"] = load_image(icon_path.path_join("Spider_Leg-glow.svg"))
			_:
				loaded_icons[icon]["sprite"] = load_image(icon_path)


func _exit_tree() -> void:
	if thread == null:
		return
	thread.wait_to_finish()
