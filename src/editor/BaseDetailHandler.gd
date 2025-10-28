extends Node
class_name BaseDetailHandler

@export var base: StringProperty
@export var detail: StringProperty
@export var color_channel_editor: ColorChannelEditor


func _ready() -> void:
	base.input.focus_entered.connect(_on_property_focus_entered)
	detail.input.focus_entered.connect(_on_property_focus_entered)


func _on_property_focus_entered() -> void:
	if color_channel_editor.button_group.get_pressed_button():
		color_channel_editor.button_group.get_pressed_button().set_pressed(false)


func _on_base_color_value_changed(base_channel: String) -> void:
	var existing_color_channels := LevelManager.current_level.color_channels.map(func(channel): return channel.associated_group.trim_prefix(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
	if base_channel != "" and not base_channel in existing_color_channels:
		base.set_value_no_signal("")
		return
	var objects_base: Array[Node2D]
	objects_base.assign($"../EditHandler".selection.map(into_base).map(use_hsv_watcher))
	clear_color_channels(objects_base)
	if base_channel == "":
		objects_base.map(_reset_color)
		return
	objects_base.map(func(object): object.add_to_group(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + base_channel, true))
	var watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + base_channel)
	watcher.refresh_objects_color(objects_base)


func _on_detail_color_value_changed(value:Variant) -> void:
	var detail_channel := value as String
	var existing_color_channels := LevelManager.current_level.color_channels.map(func(channel): return channel.associated_group.trim_prefix(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
	if not detail_channel in existing_color_channels:
		detail.set_value_no_signal("")
		return
	var objects_detail: Array = (
		$"../EditHandler".selection
			.map(func(object): return object.get_node_or_null(^"Detail") as Node2D)
			.filter(func(object): return object != null)
			.map(use_hsv_watcher)
	)
	clear_color_channels(objects_detail)
	if detail_channel == "":
		objects_detail.map(_reset_color)
		return
	objects_detail.map(func(object): object.add_to_group(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + detail_channel, true))
	var watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + detail_channel)
	watcher.refresh_objects_color(objects_detail)
	

func clear_color_channels(selection: Array) -> void:
	for color_channel in LevelManager.current_level.color_channels:
		selection.map(func(object): object.remove_from_group(color_channel.associated_group))


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	var group_is_color_channel := func(group: StringName): print(group); return group.begins_with(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX)
	# Base
	var objects_base: Array[Node2D]
	objects_base.assign(selection.map(into_base).map(use_hsv_watcher))
	var base_channel_opt: Variant = objects_base.back().get_groups().front()
	var base_channel: String
	if base_channel_opt:
		base_channel = base_channel_opt
	if base_channel.is_empty():
		base.set_value_no_signal("")
	else:
		base.set_value_no_signal(base_channel.trim_prefix(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
		var base_watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + base_channel)
		base_watcher.refresh_objects_color(objects_base)
	# Detail
	var objects_detail: Array = (
		selection
			.map(func(object): return object.get_node_or_null(^"Detail") as Node2D)
			.filter(func(object): return object != null)
			.map(use_hsv_watcher)
	)
	if objects_detail.is_empty():
		return
	var detail_channel_opt: Variant = objects_detail.back().get_groups().filter(group_is_color_channel).front()
	var detail_channel: String
	if detail_channel_opt:
		detail_channel = detail_channel_opt
	if detail_channel.is_empty():
		detail.set_value_no_signal("")
	else:
		detail.set_value_no_signal(detail_channel.trim_prefix(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
		var detail_watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + detail_channel)
		detail_watcher.refresh_objects_color(objects_detail)


func _reset_color(object: Node) -> void:
	object = use_hsv_watcher(object)
	object.modulate = Color.WHITE


static func use_hsv_watcher(object: Node) -> Node:
	var hsv_watcher: HSVWatcher = object.get_node_or_null(^"HSVWatcher")
	return hsv_watcher if hsv_watcher else object


static func into_base(object: Node2D) -> Node2D:
	var _base: Node2D = object.get_node_or_null(^"Base")
	return _base if _base else object
