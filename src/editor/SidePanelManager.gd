class_name SidePanelManager
extends Node

@export var side_panel: PanelContainer
@export var object_name: LineEdit

@export var group_parent: BoolProperty

@export_group("Colors")
@export var object_color_properties: VBoxContainer
@export var hsv_shift: FoldableContainer


func _ready() -> void:
	object_name.text_submitted.connect(update_object_name)
	group_parent.value_changed.connect(_on_group_parent_value_changed)
	_on_edit_handler_selection_changed(Selection.EMPTY())


func _on_edit_handler_selection_changed(selection: Selection) -> void:
	object_name.visible = not selection.is_empty()
	if selection.size() == 1:
		object_name.text = selection.first().name
		object_name.editable = selection.first() is not Player
		group_parent.set_value_no_signal(selection.first().has_meta("group_parent"))
		group_parent.set_input_state(true)
	elif selection.size() > 1:
		object_name.text = "%s objects" % selection.size()
		object_name.editable = false
		group_parent.set_value_no_signal(false)
		group_parent.set_input_state(false)

	var selection_is_empty: bool = selection.is_empty()
	var is_static_body := func(object: Node2D): return object is StaticBody2D
	var selection_is_interactable: bool = not selection_is_empty and selection.map(InteractableEditor.player_to_interactable).all(InteractableEditor.is_interactable)
	var selection_is_static_body: bool = not selection_is_empty and selection.all(is_static_body)

	object_color_properties.visible = not (selection.is_empty() or (selection.size() == 1 and selection.first() is Player))
	if selection.size() == 1 and selection.first() is Player:
		hsv_shift.visible = true


func update_object_name(new_name: String):
	var object: Node2D = $"../EditHandler".selection.first()
	var previous_name: String = object.name
	var sanitized_new_name: String = new_name.validate_node_name()
	var path_ref := PathRef.new(object)
	Editor.version_history.create_action("Renamed %s to %s" % [previous_name, sanitized_new_name])
	Editor.version_history.add_do_method(
		func():
			path_ref.rename(sanitized_new_name)
			object_name.text = sanitized_new_name
	)
	Editor.version_history.add_undo_method(
		func():
			path_ref.rename(previous_name)
			object_name.text = previous_name
	)
	Editor.version_history.commit_action()
	get_viewport().gui_release_focus() # Restore editor keybinds


func _on_group_parent_value_changed(value: bool) -> void:
	var selection = $"../EditHandler".selection
	if selection.size() != 1:
		return
	if value:
		selection[0].set_meta("group_parent", true)
	else:
		selection[0].remove_meta("group_parent")
