extends Control
class_name GroupEditor

const NONSHARED_GROUP_COLOR: Color = Color("#8dffcc")
const GROUP_PREFIX: String = "g_"

@export var line_edit: LineEdit
@export var confirm_button: Button
@export var group_container: Container

var selected_objects: Array[Node2D]
var group_buttons: Dictionary[String, Button]


func _populate_group_list(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	# Groups of all objects
	var all_groups: Array[StringName]
	for object in selection:
		if object.get_groups().is_empty():
			continue
		all_groups.append_array(object.get_groups())
	all_groups.assign(ArrayUtils.to_set(all_groups).filter(is_godot_group))
	# Groups that all objects are in
	var shared_groups: Array[StringName]
	shared_groups.assign(selection.reduce(func(accum: Array, object: Node2D): return ArrayUtils.intersect(accum, object.get_groups()), all_groups))
	# Additive pass
	for group in all_groups:
		if not group or group in group_buttons.keys():
			continue
		_create_group_button(group)
	# Substractive pass
	for old_group in group_buttons:
		if not old_group or old_group in all_groups:
			continue
		group_buttons[old_group].queue_free()
		group_buttons.erase(old_group)
	# Shared/non-shared groups pass
	for group in group_buttons:
		group_buttons[group].modulate = Color.WHITE if group in shared_groups else NONSHARED_GROUP_COLOR


func _create_group_button(group: String) -> Button:
	var group_button_already_exists: bool = group_container.get_children().any(func(child: Button): return child.text == group.trim_prefix(GROUP_PREFIX))
	if group_button_already_exists:
		return
	var group_button := Button.new()
	group_button.text = group.trim_prefix(GROUP_PREFIX)
	group_button.pressed.connect(_remove_group.bind(group_button))
	group_button.theme_type_variation = &"GroupButton"
	group_container.add_child(group_button)
	group_buttons[group] = group_button
	return group_button


func _add_selection_to_group(selection: Array[Node2D], group: String) -> void:
	var has_group: bool = group in group_buttons.keys()
	if not has_group:
		if group == GROUP_PREFIX:
			return
		selection.map(func(object): object.add_to_group(group, true))
	elif group_buttons[group].modulate == NONSHARED_GROUP_COLOR:
		selection.map(func(object: Node2D): object.add_to_group(group, true))
		group_buttons[group].modulate = Color.WHITE


func _remove_group_from_selection(selection: Array[Node2D], group: String):
	selection.map(func(object: Node2D): object.remove_from_group(group))
	group_buttons.erase(group)


func _remove_group(group_button: Button) -> void:
	get_viewport().gui_release_focus()
	var group: String = GROUP_PREFIX + group_button.text
	var do_remove_group := func(_selected_objects: Array[Node2D], _group: String):
		_remove_group_from_selection(_selected_objects, _group)
		group_container.remove_child(group_button)
	var undo_remove_group := func(_selected_objects: Array[Node2D], _group: String):
		_add_selection_to_group(_selected_objects, _group)
		group_container.add_child(group_button)
	var selected_objects_snapshot := selected_objects.duplicate()
	var version_history: UndoRedo = LevelManager.current_level.version_history
	version_history.create_action("Removed group %s from %s objects" % [group, selected_objects.size()])
	version_history.add_do_method(do_remove_group.bind(selected_objects_snapshot, group))
	version_history.add_undo_method(undo_remove_group.bind(selected_objects_snapshot, group))
	version_history.commit_action()


func _add_group(group: String) -> void:
	var group_button: Button = _create_group_button(group)
	var do_add_group := func(_selected_objects: Array[Node2D], _group: String):
		_add_selection_to_group(_selected_objects, _group)
		group_container.add_child(group_button)
	var undo_add_group := func(_selected_objects: Array[Node2D], _group: String):
		_remove_group_from_selection(_selected_objects, _group)
		group_container.remove_child(group_button)
	var selected_objects_snapshot := selected_objects.duplicate()
	var version_history: UndoRedo = LevelManager.current_level.version_history
	version_history.create_action("Added group %s to %s objects" % [group, selected_objects.size()])
	version_history.add_do_method(do_add_group.bind(selected_objects_snapshot, group))
	version_history.add_undo_method(undo_add_group.bind(selected_objects_snapshot, group))
	version_history.commit_action()


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	selected_objects = selection
	_populate_group_list(selection)


func _on_line_edit_text_submitted(new_text: String) -> void:
	_add_group(GROUP_PREFIX + new_text)
	line_edit.clear()
	get_viewport().gui_release_focus()


func _on_button_pressed() -> void:
	_add_group(GROUP_PREFIX + line_edit.get_text())
	line_edit.clear()
	get_viewport().gui_release_focus()


static func is_godot_group(group: StringName) -> bool:
	return group.begins_with(GROUP_PREFIX)
