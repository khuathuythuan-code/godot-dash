@tool
extends Property
class_name ResourceProperty

signal value_changed(value: Resource)

@export var default: Resource
@warning_ignore("unused_private_class_variable")
@export_tool_button("Refresh") var _refresh = refresh

var indentation_container: VBoxContainer
var resource_properties: Array


func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	var margin_container = NodeUtils.get_node_or_add(
		NodeUtils.get_node_or_add(self, "PanelContainer", PanelContainer, NodeUtils.INTERNAL),
		"MarginContainer",
		MarginContainer,
		NodeUtils.INTERNAL) as MarginContainer
	indentation_container = NodeUtils.get_node_or_add(
		margin_container,
		"VBoxContainer",
		VBoxContainer,
		NodeUtils.INTERNAL)
	assert(default != null, "Default needs to be a valid Resource")
	var resource_is_native_class: bool = default.get_script() == null
	if resource_is_native_class:
		resource_properties = default.get_property_list()
	else:
		resource_properties = default.get_script().get_script_property_list()
	resource_properties.remove_at(0)
	resource_properties = resource_properties \
			.filter(func(property): return property.usage & PROPERTY_USAGE_EDITOR != 0 and not property.name.contains("resource") and not property.name == "script") \
			.map(func(property): return property.name)
	reset()
	var index: int
	for child in get_children(false):
		child.hide()
		var child_duplicate = child.duplicate()
		child_duplicate.show()
		index = _connect_child_properties(child_duplicate, index)
		indentation_container.add_child(child_duplicate)
	renamed.connect(refresh)
	refresh()


func refresh() -> void:
	label.text = name
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Set defaults for individual fields
	var fields: Array[Property]
	fields.assign(NodeUtils.get_children_of_type(indentation_container, Property, true))
	for i in fields.size():
		var field_input: Property = fields[i]
		var field_name: String = resource_properties[i]
		var field_value: Variant = default.get(field_name)
		if field_value == null and field_input is not Node2DProperty:
			continue
		field_input.default = field_value
	vertical = true
	if Engine.is_editor_hint():
		reset()


func set_value(new_value: Resource) -> void:
	set_value_no_signal(new_value)
	value_changed.emit(new_value)


func set_value_no_signal(new_value: Resource) -> void:
	_value = new_value.duplicate(true)
	var fields: Array = NodeUtils.get_children_of_type(indentation_container, Property, true)
	for i in fields.size():
		var field_input = fields[i]
		var field_name = resource_properties[i]
		var field_value = _value.get(field_name)
		if field_value == null and field_input is not Node2DProperty:
			continue
		if field_input is Node2DProperty:
			field_value = LevelManager.current_level.get_node(field_value)
		field_input.set_value_no_signal(field_value)


func get_value() -> Resource:
	return _value.duplicate(true)


func reset() -> void:
	set_value(default)


func set_input_state(enabled: bool) -> void:
	NodeUtils.get_children_of_type(indentation_container, Property, true).map(func(input): input.set_input_state(enabled))


func _connect_child_properties(node: Node, index: int, depth: int = 0) -> int:
	if depth == 4:
		return index
	if node is Property:
		node.value_changed.connect(func(value):
			if node is Node2DProperty:
				if LevelManager.current_level == null:
					value = ^""
				else:
					value = LevelManager.current_level.get_path_to(value)
			_value = _value.duplicate(true)
			_value.set(resource_properties[index], value)
			value_changed.emit(_value))
		index += 1
	elif node is FoldableContainer and node.get_child(0) is BoxContainer:
		for child in node.get_child(0).get_children():
			index = _connect_child_properties(child, index, depth + 1)
	return index
