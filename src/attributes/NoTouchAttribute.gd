class_name NoTouchAttribute
extends Attribute

@onready var parent := get_parent() as CollisionObject2D


func _ready() -> void:
	if parent is Area2D:
		parent.monitoring = false
		return
	for shape_owner in parent.get_shape_owners():
		parent.shape_owner_set_disabled(shape_owner, true)


func _exit_tree() -> void:
	if parent is Area2D:
		parent.monitoring = true
		return
	for shape_owner in parent.get_shape_owners():
		parent.shape_owner_set_disabled(shape_owner, false)
