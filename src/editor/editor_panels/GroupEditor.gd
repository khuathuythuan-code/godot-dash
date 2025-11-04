extends Control
class_name GroupEditor

@export var line_edit: LineEdit
@export var confirm_button: Button
@export var group_container: Container

var selected_objects: Array[Node2D]
var group_buttons: Dictionary[String, Button]

const NONSHARED_GROUP_COLOR: Color = Color("#8dffcc")
const GROUP_PREFIX: String = "g_"


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
	for new_group in all_groups:
		if not new_group or new_group in group_buttons.keys():
			continue
		group_buttons[new_group] = Button.new()
		group_buttons[new_group].text = new_group.trim_prefix(GROUP_PREFIX)
		group_buttons[new_group].pressed.connect(_remove_group)
		group_buttons[new_group].theme_type_variation = &"GroupButton"
		group_container.add_child(group_buttons[new_group])
	# Substractive pass
	for old_group in group_buttons:
		if not old_group or old_group in all_groups:
			continue
		group_buttons[old_group].queue_free()
		group_buttons.erase(old_group)
	# Shared/non-shared groups pass
	for group in group_buttons:
		group_buttons[group].modulate = Color.WHITE if group in shared_groups else NONSHARED_GROUP_COLOR


func _update_groups(selection: Array[Node2D], group: String, add: bool) -> void:
	if not add:
		selection.map(func(object): object.remove_from_group(group))
		group_buttons.erase(group)
		return
	if not group in group_buttons.keys():
		if group == GROUP_PREFIX:
			return
		selection.map(func(object): object.add_to_group(group, true))
		var group_button := Button.new()
		group_button.text = group.trim_prefix(GROUP_PREFIX)
		group_button.pressed.connect(_remove_group)
		group_button.theme_type_variation = &"GroupButton"
		group_container.add_child(group_button)
		group_buttons[group] = group_button
	elif group_buttons[group].modulate == NONSHARED_GROUP_COLOR:
		selection.map(func(object): object.add_to_group(group, true))
		group_buttons[group].modulate = Color.WHITE


func _remove_group() -> void:
	var selected_group_button: Button = get_viewport().gui_get_focus_owner()
	var group: String = GROUP_PREFIX + selected_group_button.text
	_update_groups(selected_objects, group, false)
	get_viewport().gui_release_focus()
	selected_group_button.queue_free()


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	selected_objects = selection
	_populate_group_list(selection)


func _on_line_edit_text_submitted(new_text:String) -> void:
	_update_groups(selected_objects, GROUP_PREFIX + new_text, true)
	# TODO "keep focus" doesn't work
	if not Input.is_action_pressed(&"ui_accept_keep_focus"):
		get_viewport().gui_release_focus()
	line_edit.clear()


func _on_button_pressed() -> void:
	_update_groups(selected_objects, GROUP_PREFIX + line_edit.get_text(), true)
	get_viewport().gui_release_focus()
	line_edit.clear()


static func is_godot_group(group: StringName) -> bool:
	return group.begins_with(GROUP_PREFIX)
