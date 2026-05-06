@tool
class_name BlockPaletteRef
extends Node

@export var type: EditorSelectionCollider.Type:
	set(value):
		type = value
		notify_property_list_changed()
@export var id: int
@export var object: PackedScene


func _ready() -> void:
	if type == EditorSelectionCollider.Type.INTERACTABLE and not Engine.is_editor_hint():
		id = hash(object)
