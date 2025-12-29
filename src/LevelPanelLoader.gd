extends VBoxContainer

const LEVEL_DIR: String = "user://created_levels/levels/"
@export var import_dialog: FileDialog
@export var level_already_exists_dialog: ConfirmationDialog


func _ready() -> void:
	refresh()


func refresh() -> void:
	for child in get_children():
		child.queue_free()

	var dir := DirAccess.open(LEVEL_DIR)
	if dir.get_files().size() == 0:
		var label: Label = Label.new()
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = "No levels found."
		add_child(label)
		return

	var scene: PackedScene = load("res://scenes/components/game_components/LevelPanel.tscn")
	for file_name: String in dir.get_files():
		var level_name: String = file_name.replace(".json", "")
		var panel: HBoxContainer = scene.instantiate()
		var play_button: Button = panel.get_node("Play")
		var edit_button: Button = panel.get_node("Edit")
		var remove_button: Button = panel.get_node("Remove")
		play_button.text = level_name
		play_button.pressed.connect(_play_level.bind(file_name))
		edit_button.pressed.connect(_edit_level.bind(file_name))
		remove_button.pressed.connect(_remove_level.bind(file_name))
		add_child(panel)


func _play_level(level_name: String) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelPlay.ogg")
	var fade_screen = get_node("/root/TitleScreen/FadeScreenLayer/FadeScreen")
	fade_screen.fade_in(0.5, Tween.EASE_IN, Tween.TRANS_SINE)
	await get_tree().create_timer(0.5).timeout
	LevelManager.current_level_name = name
	LevelManager.attempt = 0
	LevelManager.current_level_path = LEVEL_DIR + level_name
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Playing a level")
		DiscordRPCHandler.refresh()
	get_tree().change_scene_to_packed(AssetManager.game_scene_packed)


func _edit_level(level_name: String) -> void:
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Creating a level")
		DiscordRPCHandler.refresh()
	var file := FileAccess.open(LEVEL_DIR + level_name, FileAccess.READ)
	var json_string: String = file.get_as_text()
	file.close()
	Editor.level_data_snapshot = JSON.parse_string(json_string)
	get_tree().change_scene_to_packed(AssetManager.editor_packed)


func _remove_level(level_name: String) -> void:
	OS.move_to_trash(ProjectSettings.globalize_path(LEVEL_DIR + level_name))
	refresh()


func _open_importer() -> void:
	import_dialog.show()


func _import_level(path: String) -> void:
	var keep_original = import_dialog.get_selected_options()["Keep original level file"]
	var reader = ZIPReader.new()
	reader.open(path)
	var files := reader.get_files()
	var level_dir := DirAccess.open("user://created_levels/levels")
	var song_dir := DirAccess.open("user://created_levels/songs")
	var font_dir := DirAccess.open("user://created_levels/fonts")
	var level_path: String
	if not "json" in Array(files).map(func(file): return file.get_extension()):
		Toasts.error("This exported level doesn't contain a valid JSON file and can't be imported.")
		return
	for file_path in files:
		var dir: DirAccess = (
			level_dir if LevelOperationsHandler.file_is_level(file_path) else song_dir if LevelOperationsHandler.file_is_song(file_path) else font_dir if LevelOperationsHandler.file_is_font(file_path) else null
		)
		if not dir:
			push_error("Invalid file: %s" % file_path)
		var buffer := reader.read_file(file_path)
		match dir:
			level_dir:
				level_path = dir.get_current_dir().path_join(file_path)
				if FileAccess.file_exists(level_path):
					level_already_exists_dialog.show()
					level_already_exists_dialog.confirmed.connect(LevelOperationsHandler._import_overwrite.bind(level_path, buffer))
					await level_already_exists_dialog.visibility_changed
				else:
					var file = FileAccess.open(dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
					file.store_buffer(buffer)
			_:
				var file = FileAccess.open(dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
				file.store_buffer(buffer)
	reader.close()
	refresh()
	if not keep_original:
		OS.move_to_trash(path)
