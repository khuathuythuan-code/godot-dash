class_name BaseDetailHandler
extends Node

@export var base: StringProperty
@export var detail: StringProperty
@export var color_channel_editor: ColorChannelEditor


func _ready() -> void:
	base.input.focus_entered.connect(_on_property_focus_entered)
	detail.input.focus_entered.connect(_on_property_focus_entered)


func clear_color_channels(selection: Array) -> void:
	for color_channel in LevelManager.current_level.color_channels:
		selection.map(func(object): object.remove_from_group(color_channel.associated_group))


func _load_base(objects_base: Array[HSVWatcher]) -> void:
	var base_groups: Array[StringName] = objects_base.back().get_groups()
	if base_groups.is_empty():
		base.set_value_no_signal("")
		return
	var base_channel: StringName = base_groups[0]
	if base_channel.is_empty():
		base.set_value_no_signal("")
		return
	base.set_value_no_signal(base_channel.trim_prefix(Constants.COLOR_CHANNEL_GROUP_PREFIX))
	var base_watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + base_channel)
	base_watcher.refresh_objects_color(objects_base)


func _load_detail(objects_detail: Array[HSVWatcher]) -> void:
	if objects_detail.is_empty():
		return
	var detail_groups: Array[StringName] = objects_detail.back().get_groups()
	if detail_groups.is_empty():
		detail.set_value_no_signal("")
		return
	var detail_channel: StringName = detail_groups[0]
	if detail_channel.is_empty():
		detail.set_value_no_signal("")
		return
	detail.set_value_no_signal(detail_channel.trim_prefix(Constants.COLOR_CHANNEL_GROUP_PREFIX))
	var detail_watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + detail_channel)
	detail_watcher.refresh_objects_color(objects_detail)


func _on_edit_handler_selection_changed(selection: Selection) -> void:
	if selection.is_empty() or (selection.size() == 1 and selection.first() is Player):
		return
	# Base
	var objects_base: Array[HSVWatcher]
	objects_base.assign(selection.map_generic(into_base).map(use_hsv_watcher))
	_load_base(objects_base)
	# Detail
	var objects_detail: Array[HSVWatcher]
	objects_detail.assign(
		selection.map_generic(func(object): return object.get_node_or_null(^"Detail") as Node2D).filter(ArrayUtils.flatten).map(use_hsv_watcher),
	)
	_load_detail(objects_detail)


func _on_property_focus_entered() -> void:
	if color_channel_editor.button_group.get_pressed_button():
		color_channel_editor.button_group.get_pressed_button().set_pressed(false)


func _on_base_color_interaction_ended(base_channel: String, previous_base_channel: String) -> void:
	var existing_color_channels := LevelManager.current_level.color_channels.map(func(channel): return channel.associated_group.trim_prefix(Constants.COLOR_CHANNEL_GROUP_PREFIX))
	if not base_channel.is_empty() and not base_channel in existing_color_channels:
		base.set_value_no_signal("")
		return
	var objects_base: Array[NodePath]
	objects_base.assign($"../EditHandler".selection.map_generic(into_base).map(use_hsv_watcher).map(func(hsv_watcher: HSVWatcher): return Editor.root.level.get_path_to(hsv_watcher)))
	var map_object_base_to_channel := func(accum: Dictionary, hsv_watcher_path: NodePath):
		var groups: Array[StringName] = Editor.root.level.get_node(hsv_watcher_path).get_groups()
		accum[hsv_watcher_path] = groups[0] if groups.size() > 0 else &""
		return accum
	var objects_base_to_channel: Dictionary[NodePath, StringName]
	objects_base_to_channel.assign(objects_base.reduce(map_object_base_to_channel, { }))

	var do_set_base_channel := func(_objects_base_path: Array[NodePath]):
		var _objects_base: Array[HSVWatcher]
		_objects_base.assign(_objects_base_path.map(func(path: NodePath): return Editor.root.level.get_node(path)))
		base.set_value_no_signal(base_channel)
		clear_color_channels(_objects_base)
		if base_channel.is_empty():
			_objects_base.map(reset_color)
			return
		_objects_base.map(func(object): object.add_to_group(Constants.COLOR_CHANNEL_GROUP_PREFIX + base_channel, true))
		var watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + Constants.COLOR_CHANNEL_GROUP_PREFIX + base_channel)
		watcher.refresh_objects_color(_objects_base)

	var undo_set_base_channel := func(_objects_base_to_channel: Dictionary[NodePath, StringName]):
		base.set_value_no_signal(previous_base_channel)
		var _objects_base := _objects_base_to_channel.keys().map(func(path: NodePath): return Editor.root.level.get_node(path))
		clear_color_channels(_objects_base)
		for hsv_watcher_path: NodePath in _objects_base_to_channel:
			var hsv_watcher_previous_channel: StringName = _objects_base_to_channel[hsv_watcher_path]
			var hsv_watcher: HSVWatcher = Editor.root.level.get_node(hsv_watcher_path)
			if hsv_watcher_previous_channel.is_empty():
				reset_color(hsv_watcher)
				_objects_base.erase(hsv_watcher)
				continue
			hsv_watcher.add_to_group(hsv_watcher_previous_channel)
		_objects_base.map(func(object): object.add_to_group(Constants.COLOR_CHANNEL_GROUP_PREFIX + base_channel, true))
		var watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + Constants.COLOR_CHANNEL_GROUP_PREFIX + base_channel)
		watcher.refresh_objects_color(_objects_base)

	var version_history: UndoRedo = Editor.version_history
	version_history.create_action("Set base channel to '%s' on %s objects" % [base_channel, objects_base.size()])
	version_history.add_do_method(do_set_base_channel.bind(objects_base.duplicate()))
	version_history.add_undo_method(undo_set_base_channel.bind(objects_base_to_channel.duplicate()))
	version_history.commit_action()


func _on_detail_color_interaction_ended(detail_channel: String, previous_detail_channel: String) -> void:
	var existing_color_channels := LevelManager.current_level.color_channels.map(func(channel): return channel.associated_group.trim_prefix(Constants.COLOR_CHANNEL_GROUP_PREFIX))
	if not detail_channel in existing_color_channels:
		detail.set_value_no_signal("")
		return
	var objects_detail: Array[NodePath]
	objects_detail.assign(
		$"../EditHandler".selection \
		.map_generic(func(object: Node2D): return object.get_node_or_null(^"Detail") as Node2D) \
		.filter(ArrayUtils.flatten) \
		.map(use_hsv_watcher) \
		.map(func(hsv_watcher: HSVWatcher): return Editor.root.level.get_path_to(hsv_watcher)),
	)
	var map_object_detail_to_channel := func(accum: Dictionary, hsv_watcher_path: NodePath):
		var groups: Array[StringName] = Editor.root.level.get_node(hsv_watcher_path).get_groups()
		accum[hsv_watcher_path] = groups[0] if groups.size() > 0 else &""
		return accum
	var objects_detail_to_channel: Dictionary[NodePath, StringName]
	objects_detail_to_channel.assign(objects_detail.reduce(map_object_detail_to_channel, { }))

	var do_set_detail_channel := func(_objects_detail_path: Array[NodePath]):
		var _objects_detail: Array[HSVWatcher]
		_objects_detail.assign(_objects_detail_path.map(func(path: NodePath): return Editor.root.level.get_node(path)))
		detail.set_value_no_signal(detail_channel)
		clear_color_channels(_objects_detail)
		if detail_channel.is_empty():
			_objects_detail.map(reset_color)
			return
		_objects_detail.map(func(object): object.add_to_group(Constants.COLOR_CHANNEL_GROUP_PREFIX + detail_channel, true))
		var watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + Constants.COLOR_CHANNEL_GROUP_PREFIX + detail_channel)
		watcher.refresh_objects_color(_objects_detail)

	var undo_set_detail_channel := func(_objects_detail_to_channel: Dictionary[NodePath, StringName]):
		detail.set_value_no_signal(previous_detail_channel)
		var _objects_detail := _objects_detail_to_channel.keys().map(func(path: NodePath): return Editor.root.level.get_node(path))
		clear_color_channels(_objects_detail)
		for hsv_watcher_path: NodePath in _objects_detail_to_channel:
			var hsv_watcher_previous_channel: StringName = _objects_detail_to_channel[hsv_watcher_path]
			var hsv_watcher: HSVWatcher = Editor.root.level.get_node(hsv_watcher_path)
			if hsv_watcher_previous_channel.is_empty():
				reset_color(hsv_watcher)
				_objects_detail.erase(hsv_watcher)
				continue
			hsv_watcher.add_to_group(hsv_watcher_previous_channel)
		_objects_detail.map(func(object): object.add_to_group(Constants.COLOR_CHANNEL_GROUP_PREFIX + detail_channel, true))
		var watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + Constants.COLOR_CHANNEL_GROUP_PREFIX + detail_channel)
		watcher.refresh_objects_color(_objects_detail)

	var version_history: UndoRedo = Editor.version_history
	version_history.create_action("Set detail channel to '%s' on %s objects" % [detail_channel, objects_detail.size()])
	version_history.add_do_method(do_set_detail_channel.bind(objects_detail.duplicate()))
	version_history.add_undo_method(undo_set_detail_channel.bind(objects_detail_to_channel.duplicate()))
	version_history.commit_action()


static func reset_color(hsv_watcher: HSVWatcher) -> void:
	hsv_watcher.modulate = Color.WHITE


static func use_hsv_watcher(object: Node) -> HSVWatcher:
	return object.get_node(^"HSVWatcher")


static func into_base(object: Node2D) -> Node2D:
	var _base: Node2D = object.get_node_or_null(^"Base")
	return _base if _base else object
