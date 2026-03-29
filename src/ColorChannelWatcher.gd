class_name ColorChannelWatcher
extends Node

const WATCHER_GROUP_PREFIX := "watcher_"

static var DEFAULT_DATA := ColorChannelData.new()

var data: ColorChannelData


func _init(new_data: ColorChannelData) -> void:
	data = new_data
	data.watcher = self
	add_to_group(WATCHER_GROUP_PREFIX + data.associated_group)
	data.changed.connect(refresh_objects_color)


func _exit_tree() -> void:
	if is_queued_for_deletion():
		reset_objects_color()


func _ready() -> void:
	refresh_objects_color()


func refresh_objects_color(objects: Array = [], _data: ColorChannelData = data) -> void:
	if objects.is_empty():
		objects = get_tree().get_nodes_in_group(_data.associated_group)
	for object: HSVWatcher in objects:
		if _data.copy:
			match _data.copied_channel:
				Constants.SpecialColorChannel.BACKGROUND:
					object.modulate = LevelManager.current_level.background_color
				Constants.SpecialColorChannel.GROUND:
					object.modulate = LevelManager.current_level.ground_color
				Constants.SpecialColorChannel.LINE:
					object.modulate = LevelManager.current_level.line_color
				Constants.SpecialColorChannel.P1:
					pass
				Constants.SpecialColorChannel.P2:
					pass
				Constants.SpecialColorChannel.GLOW:
					pass
		else:
			object.modulate = _data.color
		object.modulate.h += _data.hsv_shift[0]
		object.modulate.s += _data.hsv_shift[1]
		object.modulate.v += _data.hsv_shift[2]
		object.base_intensity = _data.intensity
		object.base_alpha = _data.alpha
		object.update_color()


func remove_objects_from_group(group_objects: Array[Node]) -> void:
	group_objects.map(func(object: Node): object.remove_from_group(data.associated_group))


func reset_objects_color() -> void:
	var group_objects: Array[Node] = get_tree().get_nodes_in_group(data.associated_group)
	refresh_objects_color(group_objects, DEFAULT_DATA)
	remove_objects_from_group(group_objects)
