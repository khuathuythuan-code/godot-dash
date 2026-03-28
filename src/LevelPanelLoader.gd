extends VBoxContainer

@export var rating_colors: Gradient
@export var subscene_manager: SubsceneManager
@export var import_dialog: FileDialog
@export var level_already_exists_dialog: ConfirmationDialog
@export var sort_by: OptionButton
@export var order: OptionButton
@export var fade_screen: FadeScreen

var levels: Dictionary[String, Control]


func _ready() -> void:
	sort_by.item_selected.connect(reorder.unbind(1))
	order.item_selected.connect(reorder.unbind(1))
	refresh()


func refresh() -> void:
	levels.clear()
	for child in get_children():
		child.queue_free()

	var dir := DirAccess.open(Constants.LEVEL_DIR)
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
		var panel: LevelPanel = scene.instantiate()
		var level_data: Dictionary = JSON.parse_string(FileAccess.open(Constants.LEVEL_DIR + file_name, FileAccess.READ).get_as_text())
		panel.title.text = level_name
		panel.creator.text = level_data.creator
		panel.description.text = level_data.description
		panel.version.text = "v" + level_data.game_version
		if level_data.game_version != ProjectSettings.get_setting("application/config/version"):
			panel.version.modulate = Color.RED
		panel.rating.text = str(int(level_data.rating)) if level_data.rating != -1 else "?"
		panel.rating_outline.modulate = rating_colors.get_color(level_data.rating + 1)
		if not level_data.flashing_lights:
			panel.flashing_lights.hide()
		panel.play_button.pressed.connect(_play_level.bind(file_name))
		panel.edit_button.pressed.connect(_edit_level.bind(file_name))
		panel.remove_button.pressed.connect(_remove_level.bind(file_name))
		panel.data = level_data
		levels[file_name] = panel
		add_child(panel)

	await get_tree().process_frame
	reorder()


func reorder() -> void:
	var children: Array
	for child in get_children():
		children.append(child)
	# Alphabetical
	children.sort_custom(func(a, b): return a.get_node("Play/HBoxContainer/VBoxContainer/Title").text.to_lower() > b.get_node("Play/HBoxContainer/VBoxContainer/Title").text.to_lower())
	match sort_by.selected:
		1: # Rating
			children.sort_custom(func(a, b): return a.data.rating < b.data.rating)
		2: # Creator
			children.sort_custom(func(a, b): return a.data.creator.to_lower() > b.data.creator.to_lower())
		3: # Creation Date
			children.sort_custom(func(a, b): return a.data.creation_date < b.data.creation_date)

	for child in children:
		move_child(child, 0)

	# Flip order
	if order.selected == 1:
		for child in get_children():
			move_child(child, 0)


func _play_level(level_name: String) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelPlay.ogg")
	fade_screen.fade_in()
	subscene_manager.history.change_phantomcamera(subscene_manager.active_pcam, subscene_manager.quit_game_camera)
	subscene_manager.zoom_in_title_screen_layer()
	await get_tree().create_timer(0.5).timeout
	LevelManager.current_level_name = name
	LevelManager.attempt = 0
	LevelManager.current_level_path = Constants.LEVEL_DIR + level_name
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Playing a level")
		DiscordRPCHandler.refresh()
	get_tree().change_scene_to_packed(AssetManager.game_scene_packed)


func _edit_level(level_file_name: String) -> void:
	var file := FileAccess.open(Constants.LEVEL_DIR + level_file_name, FileAccess.READ)
	var json_string: String = file.get_as_text()
	file.close()
	Editor.level_file_path = level_file_name
	Editor.level_data_snapshot = JSON.parse_string(json_string)
	subscene_manager._on_editor_pressed()


func _remove_level(level_name: String) -> void:
	OS.move_to_trash(ProjectSettings.globalize_path(Constants.LEVEL_DIR + level_name))
	levels[level_name].queue_free()
	levels.erase(level_name)
	# Node is freed the next frame
	if get_child_count() <= 1:
		var label: Label = Label.new()
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = "No levels found."
		add_child(label)


func _open_importer() -> void:
	import_dialog.show()


func _import_level(path: String) -> void:
	var keep_original = import_dialog.get_selected_options()["Keep original level file"]
	var reader = ZIPReader.new()
	reader.open(path)
	var files := reader.get_files()
	var level_dir := DirAccess.open(Constants.LEVEL_DIR)
	var song_dir := DirAccess.open(Constants.SONG_DIR)
	var font_dir := DirAccess.open(Constants.FONT_DIR)
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
