@abstract
class_name Attribute
extends Node
## Equivalent of Marker for non-Interactable nodes

const ATTRIBUTE_PATH_ROOT: String = "res://src/attributes/"


func _enter_tree() -> void:
	register()


func _exit_tree() -> void:
	unregister()


func register() -> void:
	var parent: Node2D = get_parent()
	var current_attributes: Array = parent.get_meta(&"attributes", [])
	if not get_script().get_global_name() in current_attributes:
		current_attributes.append(get_script().resource_path.trim_prefix(ATTRIBUTE_PATH_ROOT))
	parent.set_meta(&"attributes", current_attributes)


func unregister() -> void:
	var parent: Node2D = get_parent()
	var current_attributes: Array = parent.get_meta(&"attributes", [])
	current_attributes.erase(get_script().resource_path.trim_prefix(ATTRIBUTE_PATH_ROOT))
	parent.set_meta(&"attributes", current_attributes)
