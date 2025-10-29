extends Node

var thread: Thread

var loaded_songs: Dictionary[String, AudioStream]
var loaded_fonts: Dictionary[String, Font]


func load_song(path: String) -> AudioStream:
	var audio_stream: AudioStream
	if path.begins_with("uid"):
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
				printerr("Song isn't of valid type")
	loaded_songs[path] = audio_stream
	return audio_stream


func load_song_threaded_request(path: String) -> Error:
	if path.is_empty() or path == null:
		return ERR_FILE_BAD_PATH
	if thread == null:
		thread = Thread.new()
	if thread.is_started():
		thread.wait_to_finish()
	return thread.start(load_song.bind(path))


func load_song_threaded_get(path: String) -> AudioStream:
	if path.is_empty() or path == null:
		return null
	if thread.is_started():
		thread.wait_to_finish()
	return loaded_songs[path]


func unload_all() -> void:
	loaded_songs.clear()
	loaded_fonts.clear()


func load_font(path: String) -> FontFile:
	if path in loaded_fonts:
		return loaded_fonts[path]
	var loaded_font := FontFile.new()
	if path.is_empty():
		loaded_font = ThemeDB.get_project_theme().default_font.duplicate()
	else:
		var error: Error = loaded_font.load_dynamic_font(path)
		if error != OK:
			push_error("Error while loading font at %s: %s" % [path, error])
			return null
	loaded_font.multichannel_signed_distance_field = true
	loaded_font.msdf_pixel_range = 64
	loaded_font.msdf_size = 128
	loaded_fonts[path] = loaded_font
	return loaded_font


func _exit_tree() -> void:
	if thread == null:
		return
	thread.wait_to_finish()
