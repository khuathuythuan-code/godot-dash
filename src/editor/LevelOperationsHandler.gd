class_name LevelOperationsHandler
extends Node

signal level_loaded(level: Level)
signal level_saved

@export var edit_handler: EditHandler
@export var level_settings: LevelSettings
@export var open_dialog: FileDialog
@export var import_dialog: FileDialog
@export var save_as_dialog: FileDialog
@export var export_dialog: FileDialog
@export var save_changes_before_opening_dialog: ConfirmationDialog
@export var corrupted_level_dialog: AcceptDialog
@export var level_already_exists_dialog: ConfirmationDialog

@onready var editor: EditorScene = get_parent()

var autosave_toast: Toast


func _ready() -> void:
	save_changes_before_opening_dialog.add_button("Don't Save", false, "dontsave")
	save_as_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	export_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	NodeUtils.connect_once($AutosaveTimer.timeout, save_level)


func _process(_delta: float) -> void:
	if not LevelManager.level_playing and $AutosaveTimer.get_time_left() < 5.0 and not $AutosaveTimer.is_stopped():
		var autosave_message := "Autosaving in " + str(snappedf($AutosaveTimer.get_time_left(), 0.1)) + "s"
		if autosave_toast:
			autosave_toast.update_text(autosave_message)
		else:
			autosave_toast = Toasts.new_toast(autosave_message, $AutosaveTimer.get_time_left())
	if autosave_toast and LevelManager.level_playing:
		autosave_toast.dismiss()


func _unhandled_input(event: InputEvent) -> void:
	if LevelManager.level_playing:
		return
	if event.is_action_pressed(&"editor_new_level", false, true):
		_on_level_index_pressed(0)
	if event.is_action_pressed(&"editor_open_level", false, true):
		_on_level_index_pressed(1)
	if event.is_action_pressed(&"editor_import_level", false, true):
		_on_level_index_pressed(2)
	if event.is_action_pressed(&"editor_save", false, true):
		_on_level_index_pressed(3)
	if event.is_action_pressed(&"editor_save_as", false, true):
		_on_level_index_pressed(4)
	if event.is_action_pressed(&"editor_export_level", false, true):
		_on_level_index_pressed(5)


func pause_autosave() -> void:
	$AutosaveTimer.paused = true


func unpause_autosave() -> void:
	$AutosaveTimer.paused = false


func _on_level_index_pressed(index: int) -> void:
	match index:
		0: # New
			if editor.level_was_modified():
				save_changes_before_opening_dialog.dialog_text = "Save changes before opening?"
				save_changes_before_opening_dialog.show()
				save_changes_before_opening_dialog.set_meta("next", _new_level)
			else:
				_new_level()
		1: # Open
			open_dialog.show()
		2: # Import
			import_dialog.show()
		3: # Save
			save_level()
		4: # Save As
			save_as_dialog.show()
		5: # Export
			if not Editor.level_file_path.is_empty():
				export_dialog.set_current_file(Editor.level_file_path.get_basename())
			export_dialog.show()


func _new_level() -> void:
	LevelManager.game_scene.free_current_level()
	LevelManager.game_scene.reset()
	var color_channel_editor: ColorChannelEditor = editor.get_node(^"%ColorChannelEditor")
	color_channel_editor.clear_item_list()
	edit_handler.clear_selection()
	var new_level := Level.new()
	new_level.name = "New level"
	editor.level = LevelManager.game_scene.add_loaded_level(new_level)
	Editor.clear_data()
	Editor.root.reset()
	Editor.root.inspector_manager.level_settings.refresh_saveloads(new_level)
	new_level.default_background_color = Constants.DEFAULT_BACKGROUND_COLOR
	new_level.default_ground_color = Constants.DEFAULT_GROUND_COLOR
	new_level.default_line_color = Constants.DEFAULT_LINE_COLOR
	LevelManager.current_level_duration = INF
	Editor.level_file_path = ""
	# Reset player
	LevelManager.player.position = Constants.DEFAULT_PLAYER_POSITION
	for group in LevelManager.player.get_groups():
		LevelManager.player.remove_from_group(group)
	LevelManager.player.get_node(^"HSVWatcher").reset_color()
	LevelManager.player.z_index = 0

	level_loaded.emit(new_level)
	# Reset camera to default position
	editor.editor_camera.offset = Vector2(1280.0, 669.0)
	editor.editor_camera.zoom_factor = 1.25
	editor.editor_camera.zoom = Vector2.ONE * 0.8
	$AutosaveTimer.stop()


func _open_level(path: String) -> void:
	if LevelManager.level_playing:
		await editor.stop_playtest()
		return
	LevelManager.game_scene.free_current_level()
	LevelManager.game_scene.reset()
	LevelManager.game_scene.pause_menu.play_button.show()
	# Avoid name conflicts
	editor.level.name = str(hash(editor.level))
	Editor.clear_data()
	# Load level
	var level: Level = _load_level(path)
	if not level:
		return
	Editor.root.reset()
	Editor.root.inspector_manager.level_settings.refresh_saveloads(level)
	# Load song
	var song_file_path: String
	if level.song_path.begins_with("uid"):
		song_file_path = ResourceUID.get_id_path(ResourceUID.text_to_id(level.song_path)).get_file()
	else:
		song_file_path = level.song_path.get_file()
	level.song_path = "" if song_file_path.is_empty() else Constants.SONG_DIR + song_file_path
	level.set_meta(&"packed_file_path", path)
	# Remove current editor level
	var color_channel_editor: ColorChannelEditor = editor.get_node(^"%ColorChannelEditor")
	edit_handler.clear_selection()
	color_channel_editor.clear_item_list()
	# Add new level
	await get_tree().process_frame
	editor.level = LevelManager.game_scene.add_loaded_level(level)
	LevelManager.current_level_duration = INF
	level_loaded.emit(level)
	Toasts.new_toast("Opened level " + path.get_file().get_basename())
	color_channel_editor.populate_item_list()
	# Reset camera to default position
	editor.editor_camera.offset = Vector2(1280.0, 669.0)
	editor.editor_camera.zoom_factor = 1.25
	editor.editor_camera.zoom = PlayerCamera.DEFAULT_ZOOM
	$AutosaveTimer.stop()
	$AutosaveTimer.start(Config.autosave_delay * 60)


func _import_level(path: String, keep_original: bool) -> void:
	var reader = ZIPReader.new()
	reader.open(path)
	var files := reader.get_files()
	var level_dir := DirAccess.open(Constants.LEVEL_DIR)
	var song_dir := DirAccess.open(Constants.SONG_DIR)
	var font_dir := DirAccess.open(Constants.FONT_DIR)
	var level_path: String
	if not "json" in Array(files).map(func(file): return file.get_extension()):
		corrupted_level_dialog.show()
		return
	for file_path in files:
		var dir: DirAccess = (
			level_dir if file_is_level(file_path) else song_dir if file_is_song(file_path) else font_dir if file_is_font(file_path) else null
		)
		if not dir:
			push_error("Invalid file: %s" % file_path)
		var buffer := reader.read_file(file_path)
		match dir:
			level_dir:
				level_path = dir.get_current_dir().path_join(file_path)
				if FileAccess.file_exists(level_path):
					level_already_exists_dialog.show()
					level_already_exists_dialog.confirmed.connect(_import_overwrite.bind(level_path, buffer))
					await level_already_exists_dialog.visibility_changed
				else:
					var file = FileAccess.open(dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
					file.store_buffer(buffer)
			_:
				var file = FileAccess.open(dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
				file.store_buffer(buffer)
	reader.close()
	if not keep_original:
		OS.move_to_trash(path)
	_open_level(level_path)


static func _import_overwrite(level_path: String, buffer: PackedByteArray) -> void:
	var file = FileAccess.open(level_path, FileAccess.WRITE)
	file.store_buffer(buffer)


func save_level() -> void:
	if Editor.level_file_path.is_empty():
		save_as_dialog.show()
		return # save_level will get called again by the dialog
	LevelManager.game_scene.pause_menu.play_button.show()
	var file_name: String = Editor.level_file_path
	editor.level.name = file_name.get_basename()
	var level_data: Dictionary = editor.level.to_data()
	if not LevelManager.level_playing:
		# The level is saved before starting playtest, but here the creator isn't playtesting.
		Editor.level_data_snapshot = level_data
	$AutosaveTimer.stop()
	$AutosaveTimer.start(Config.autosave_delay * 60)
	var file := FileAccess.open(Constants.LEVEL_DIR + file_name, FileAccess.WRITE)
	file.store_line(JSON.stringify(level_data, "\t"))
	file.close()
	Toasts.new_toast("Saved level " + file_name.get_basename())
	Editor.level_history_version = Editor.version_history.get_version()
	level_saved.emit()


func _on_open_level_dialog_file_selected(path: String) -> void:
	if editor.level_was_modified():
		save_changes_before_opening_dialog.dialog_text = "Save changes before opening level?"
		save_changes_before_opening_dialog.show()
		save_changes_before_opening_dialog.set_meta("next", _open_level)
		save_changes_before_opening_dialog.set_meta("next_path", path)
	else:
		_open_level(path)


func _on_import_and_open_level_dialog_file_selected(path: String) -> void:
	if editor.level_was_modified():
		save_changes_before_opening_dialog.dialog_text = "Save changes before opening level?"
		save_changes_before_opening_dialog.show()
		save_changes_before_opening_dialog.set_meta("next", _import_level)
		save_changes_before_opening_dialog.set_meta("next_path", path)
		save_changes_before_opening_dialog.set_meta("next_options", import_dialog.get_selected_options()["Keep original level file"])
	else:
		_import_level(path, import_dialog.get_selected_options()["Keep original level file"])


func _on_save_level_as_dialog_file_selected(path: String) -> void:
	Editor.level_file_path = path.get_file()
	editor.level.name = path.get_file().get_basename()
	save_level()


func _on_save_changes_before_opening_confirmed() -> void:
	save_level()
	match save_changes_before_opening_dialog.get_meta("next"):
		_import_level:
			save_changes_before_opening_dialog.get_meta("next").call(save_changes_before_opening_dialog.get_meta("next_path"), save_changes_before_opening_dialog.get_meta("next_options"))
		_open_level:
			save_changes_before_opening_dialog.get_meta("next").call(save_changes_before_opening_dialog.get_meta("next_path"))
		null:
			pass
		_:
			save_changes_before_opening_dialog.get_meta("next").call()


func _on_save_changes_before_opening_custom_action(action: StringName) -> void:
	if action == &"dontsave":
		match save_changes_before_opening_dialog.get_meta("next"):
			_import_level:
				save_changes_before_opening_dialog.get_meta("next").call(save_changes_before_opening_dialog.get_meta("next_path"), save_changes_before_opening_dialog.get_meta("next_options"))
			_open_level:
				save_changes_before_opening_dialog.get_meta("next").call(save_changes_before_opening_dialog.get_meta("next_path"))
			null:
				pass
			_:
				save_changes_before_opening_dialog.get_meta("next").call()
		save_changes_before_opening_dialog.hide()


func _on_export_level_dialog_file_selected(path: String) -> Error:
	var writer = ZIPPacker.new()
	var err = writer.open(path)
	if err != OK:
		return err
	var file_name: String

	#section Level Pack
	file_name = path.get_file().get_basename() + ".json"
	writer.start_file(file_name)
	var level_data: Dictionary = editor.level.to_data()
	if not LevelManager.level_playing:
		# The level is saved before starting playtest, but here the creator isn't playtesting.
		edit_handler.selection.for_each(EditHandler.remove_selection_highlight)
		Editor.level_data_snapshot = level_data
		edit_handler.selection.for_each(EditHandler.add_selection_highlight)
	var level_bytes := JSON.stringify(level_data).to_utf8_buffer()
	writer.write_file(level_bytes)
	writer.close_file()
	#endsection

	#section Song Pack
	for song_path in editor.level.required_songs.keys():
		file_name = song_path.get_file()
		writer.start_file(file_name)
		var song_bytes := FileAccess.get_file_as_bytes(song_path)
		writer.write_file(song_bytes)
		writer.close_file()
	#endsection

	#section Font Pack
	for font_path in editor.level.required_fonts.keys():
		file_name = font_path.get_file()
		writer.start_file(file_name)
		var font_bytes := FileAccess.get_file_as_bytes(font_path)
		writer.write_file(font_bytes)
		writer.close_file()
	#endsection

	writer.close()
	Toasts.new_toast("Exported level %s in directory %s" % [path.get_file().get_basename(), path.get_base_dir()], 2.0)
	return OK


func _load_level(path: String) -> Level:
	var file := FileAccess.open(path, FileAccess.READ)
	var json_string: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		var error_message: String = "JSON Parse Error: %s in %s at line %s" % [json.get_error_message(), json_string, json.get_error_line()]
		push_error(error_message)
		corrupted_level_dialog.dialog_text = """This exported level doesn't contain a valid JSON file and can't be imported.
Error:
%s""" % error_message
		corrupted_level_dialog.show()
		return null
	if json.data is not Dictionary:
		push_error("Unexpected data")
		return null
	var level: Level = Level.from_data(json.data)
	Editor.level_file_path = path.get_file()
	return level


static func file_is_level(file_path: String) -> bool:
	return file_path.ends_with(".json")


static func file_is_song(file_path: String) -> bool:
	return file_path.ends_with(".mp3") or file_path.ends_with(".wav") or file_path.ends_with(".ogg")


static func file_is_font(file_path: String) -> bool:
	return file_path.ends_with(".ttf") or file_path.ends_with(".ttc") or file_path.ends_with(".otf")
