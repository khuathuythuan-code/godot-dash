@abstract
extends Node

class_name Component

@onready var parent := get_parent() as Interactable


func _ready() -> void:
	parent.register_public(self)


func require(component_types: Array[Script]) -> void:
	if not parent.is_node_ready():
		await parent.ready
	for component_type in component_types:
		assert(parent.has(component_type), "%s is missing %s" % [parent, component_type.get_global_name()])


func to_data(reason: Level.SerializeReason = Level.SerializeReason.SAVE) -> Dictionary:
	var fields: Array[Dictionary] = get_script().get_script_property_list()
	var is_field_serialized := func(field: Dictionary): return field.usage & PROPERTY_USAGE_STORAGE and not field.name.begins_with("_")
	var get_field_name := func(field: Dictionary): return field.name
	var field_names := PackedStringArray(fields.filter(is_field_serialized).map(get_field_name))
	var data: Dictionary
	for field_name: String in field_names:
		var field_value: Variant = _field_to_data(field_name, reason)
		if field_value == null:
			continue
		data[field_name] = field_value
	return data


func use_data(data: Dictionary) -> void:
	for field_name in data:
		_field_from_data(field_name, data[field_name])


func _field_to_data(field_name: String, _reason: Level.SerializeReason) -> Variant:
	var field_value: Variant = get(field_name)
	var is_resource := func(element: Variant): return element is Resource
	assert(
		field_value is not Resource and not (field_value is Array and field_value.any(is_resource)),
		"Any component with Resource fields must override `_field_to_data`",
	)
	return field_value


func _field_from_data(field_name: String, field_data: Variant) -> void:
	set(field_name, field_data)
