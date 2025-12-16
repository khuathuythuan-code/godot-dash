class_name SidePanelManager
extends Node

@export var side_panel: PanelContainer
@export var object_name: LineEdit

@export_group("Transform")
@export var transform_section: FoldableContainer

@export_group("Groups")
@export var group_section: FoldableContainer
@export var group_editor: GroupEditor
@export var group_parent: BoolProperty

@export_group("Interactables")
@export var interactable_section: FoldableContainer

@export_group("Attributes")
@export var attributes_section: FoldableContainer

@export_group("Colors")
@export var color_section: FoldableContainer
@export var base: StringProperty
@export var detail: StringProperty
@export var hsv_shift: FoldableContainer


func _ready() -> void:
	object_name.text_submitted.connect(update_object_name)
	group_parent.value_changed.connect(_on_group_parent_value_changed)
	color_section.folded = false
	_on_edit_handler_selection_changed(Selection.EMPTY())


func _on_edit_handler_selection_changed(selection: Selection) -> void:
	object_name.visible = not selection.is_empty()
	if selection.size() == 1:
		object_name.text = selection.first().name
		object_name.editable = true
		group_parent.set_value_no_signal(selection.first().has_meta("group_parent"))
		group_parent.set_input_state(true)
	elif selection.size() > 1:
		object_name.text = "%s objects" % selection.size()
		object_name.editable = false
		group_parent.set_value_no_signal(false)
		group_parent.set_input_state(false)

	transform_section.visible = not selection.is_empty()

	group_section.visible = not selection.is_empty()

	var selection_is_interactable: bool = selection.map(InteractableEditor.player_to_interactable).all(InteractableEditor.is_interactable)

	interactable_section.visible = not selection.is_empty() and selection_is_interactable
	interactable_section.set_deferred(&"folded", not selection_is_interactable)
	color_section.set_deferred(&"folded", selection_is_interactable and not selection.is_empty())

	attributes_section.visible = not selection.is_empty()

	for element in [base, detail, hsv_shift]:
		element.visible = not selection.is_empty()


func update_object_name(new_name: String):
	var object: Node2D = $"../EditHandler".selection.first()
	var previous_name: String = object.name
	var path_ref := PathRef.new(object)
	Editor.version_history.create_action("Renamed %s to %s" % [previous_name, new_name])
	Editor.version_history.add_do_method(
		func():
			path_ref.to_ref().name = new_name
			object_name.text = new_name
	)
	Editor.version_history.add_undo_method(
		func():
			path_ref.to_ref().name = previous_name
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
