extends VBoxContainer

@export var import_dialog: FileDialog
@export var save_dialog: FileDialog
@export var replay_already_exists_dialog: ConfirmationDialog
@export var sort_by: OptionButton
@export var order: OptionButton
@export var save: Button
@export var stop: Button

var replays: Dictionary[String, Control]

signal replay_started


func _ready() -> void:
	sort_by.item_selected.connect(reorder.unbind(1))
	order.item_selected.connect(reorder.unbind(1))
	refresh()


func _process(_delta: float) -> void:
	if not visible:
		return
	if not LevelManager.level_playing or LevelManager.player.in_replay:
		save.hide()
	else:
		save.show()
	if LevelManager.player.in_replay:
		stop.show()
	else:
		stop.hide()


func refresh() -> void:
	replays.clear()
	for child in get_children():
		child.queue_free()

	if not DirAccess.dir_exists_absolute(Constants.REPLAYS_DIR):
		DirAccess.make_dir_recursive_absolute(Constants.REPLAYS_DIR)

	var dir := DirAccess.open(Constants.REPLAYS_DIR)
	if dir.get_files().size() == 0:
		var label: Label = Label.new()
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = "No replays found."
		add_child(label)
		return

	var scene: PackedScene = load("res://scenes/components/game_components/ReplayPanel.tscn")
	for file_name: String in dir.get_files():
		var replay_name: String = file_name.replace(".res", "")
		var panel: ReplayPanel = scene.instantiate()
		panel.title.text = replay_name
		panel.start_button.pressed.connect(_start_replay.bind(file_name))
		panel.remove_button.pressed.connect(_remove_level.bind(file_name))
		replays[file_name] = panel
		add_child(panel)

	await get_tree().process_frame
	reorder()


func reorder() -> void:
	var children: Array
	for child in get_children():
		children.append(child)
	# Alphabetical
	children.sort_custom(func(a, b): return a.get_node("Start/HBoxContainer/VBoxContainer/Title").text.to_lower() > b.get_node("Start/HBoxContainer/VBoxContainer/Title").text.to_lower())

	for child in children:
		move_child(child, 0)

	# Flip order
	if order.selected == 1:
		for child in get_children():
			move_child(child, 0)


func _start_replay(path: String) -> void:
	if LevelManager.level_playing:
		LevelManager.practice_mode = false
		LevelManager.practice_level_snapshots.clear()
		LevelManager.game_scene.restart_level()
		LevelManager.player.replay = load(Constants.REPLAYS_DIR.path_join(path))
		LevelManager.player.in_replay = true
		Toasts.new_toast("Started Replay: %s" % path.replace(".res", ""))
		replay_started.emit()


func _stop_replay() -> void:
	LevelManager.player.in_replay = false
	Toasts.new_toast("Stopped Replay")


func _remove_level(replay_name: String) -> void:
	OS.move_to_trash(ProjectSettings.globalize_path(Constants.REPLAYS_DIR + replay_name))
	replays[replay_name].queue_free()
	replays.erase(replay_name)
	# Node is freed the next frame
	if get_child_count() <= 1:
		var label: Label = Label.new()
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = "No replays found."
		add_child(label)


func _open_importer() -> void:
	import_dialog.show()


func _save() -> void:
	save_dialog.show()
	await save_dialog.file_selected
	var error: Error = ResourceSaver.save(LevelManager.player.replay, Constants.REPLAYS_DIR.path_join(save_dialog.current_file), ResourceSaver.SaverFlags.FLAG_COMPRESS)
	match error:
		Error.OK:
			Toasts.new_toast("Replay saved!")
			refresh()
		_:
			Toasts.error("Could not save replay: Error %s." % error)


func _import_replay(path: String) -> void:
	var keep_original = import_dialog.get_selected_options()["Keep original level file"]
	var replay_path: String = Constants.REPLAYS_DIR.path_join(path.get_slice("/", 4))
	if not path.contains(".res"):
		Toasts.error("This replay isn't a valid resource file and can't be imported.")
		return
	var replay: Replay = load(path)
	if FileAccess.file_exists(replay_path):
		replay_already_exists_dialog.show()
		await replay_already_exists_dialog.confirmed
		DirAccess.remove_absolute(replay_path)
	print(replay_path)
	ResourceSaver.save(replay, replay_path, ResourceSaver.FLAG_COMPRESS)
	refresh()
	if not keep_original:
		OS.move_to_trash(path)
