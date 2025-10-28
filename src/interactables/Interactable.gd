extends Area2D
class_name Interactable

@warning_ignore("unused_signal")
signal interacted(player: Player)

var components: Array[Component]


func _ready() -> void:
	if has_node("Hitbox"):
		$Hitbox.debug_color = Color("00ff0033")


func register_public(component: Component) -> void:
	components.append(component)


func has(component_type: Script) -> bool:
	return components.any(func(component): return component and component.get_script() == component_type)


func query(component_type: Script) -> Component:
	var component_idx := components.find_custom(func(component): return component and component.get_script() == component_type)
	return components[component_idx] if component_idx >= 0 else null


func components_to_data() -> Dictionary[String, Dictionary]:
	assert(Editor.in_editor, "Cannot serialize outside the editor")
	var data: Dictionary[String, Dictionary]
	var should_serialize_component := func(component: Component): return not component.get_script() in InteractableEditor.COMPONENT_BLACKLIST
	var serialized_components: Array[Component]
	serialized_components.assign(components.filter(should_serialize_component))
	for serialized_component: Component in serialized_components:
		var fields: Array[Dictionary] = serialized_component.script.get_script_property_list()
		var is_field_serialized := func(field: Dictionary): return field.usage & PROPERTY_USAGE_STORAGE and not field.name.begins_with("_")
		var get_field_name := func(field: Dictionary): return field.name
		var field_names := PackedStringArray(fields.filter(is_field_serialized).map(get_field_name))
		var serialized_component_data: Dictionary
		for field_name: String in field_names:
			if serialized_component.get(field_name) == null:
				continue
			serialized_component_data[field_name] = serialized_component.get(field_name)
		var serialized_component_name: String = serialized_component.get_script().get_global_name()
		data[serialized_component_name] = serialized_component_data
	return data


func markers_to_data() -> Array:
	var serialized_markers: Array[Marker]
	var is_marker := func(component: Component): return component is Marker
	var to_name := func(marker: Marker): return marker.get_script().get_global_name()
	serialized_markers.assign(ArrayUtils.to_set(components.filter(is_marker)))
	return serialized_markers.map(to_name)
