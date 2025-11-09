extends Node
class_name BaseDetailHandler

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
		return
	var base_channel: StringName = base_groups[0]
	if base_channel.is_empty():
		base.set_value_no_signal("")
		return
	base.set_value_no_signal(base_channel.trim_prefix(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
	var base_watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + base_channel)
	base_watcher.refresh_objects_color(objects_base)


func _load_detail(objects_detail: Array[HSVWatcher]) -> void:
	if objects_detail.is_empty():
		return
	var detail_groups: Array[StringName] = objects_detail.back().get_groups()
	if detail_groups.is_empty():
		return
	var detail_channel: StringName = detail_groups[0]
	if detail_channel.is_empty():
		detail.set_value_no_signal("")
		return
	detail.set_value_no_signal(detail_channel.trim_prefix(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
	var detail_watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + detail_channel)
	detail_watcher.refresh_objects_color(objects_detail)


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	# Base
	var objects_base: Array[HSVWatcher]
	objects_base.assign(selection.map(into_base).map(use_hsv_watcher))
	_load_base(objects_base)
	# Detail
	var objects_detail: Array[HSVWatcher]
	objects_detail.assign(
		selection
			.map(func(object): return object.get_node_or_null(^"Detail") as Node2D)
			.filter(ArrayUtils.flatten)
			.map(use_hsv_watcher)
	)


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
		objects_base.map(reset_color)
		return
	objects_base.map(func(object): object.add_to_group(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + base_channel, true))
	var watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + base_channel)
	watcher.refresh_objects_color(objects_base)


func _on_detail_color_value_changed(detail_channel: String) -> void:
	var existing_color_channels := LevelManager.current_level.color_channels.map(func(channel): return channel.associated_group.trim_prefix(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX))
	if not detail_channel in existing_color_channels:
		detail.set_value_no_signal("")
		return
	var objects_detail: Array = (
		$"../EditHandler".selection
			.map(func(object): return object.get_node_or_null(^"Detail") as Node2D)
			.filter(ArrayUtils.flatten)
			.map(use_hsv_watcher)
	)
	clear_color_channels(objects_detail)
	if detail_channel == "":
		objects_detail.map(reset_color)
		return
	objects_detail.map(func(object): object.add_to_group(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + detail_channel, true))
	var watcher: ColorChannelWatcher = get_tree().get_first_node_in_group(ColorChannelWatcher.WATCHER_GROUP_PREFIX + ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX + detail_channel)
	watcher.refresh_objects_color(objects_detail)
	

static func reset_color(hsv_watcher: HSVWatcher) -> void:
	hsv_watcher.modulate = Color.WHITE


static func use_hsv_watcher(object: Node) -> HSVWatcher:
	return object.get_node(^"HSVWatcher")


static func into_base(object: Node2D) -> Node2D:
	var _base: Node2D = object.get_node_or_null(^"Base")
	return _base if _base else object
