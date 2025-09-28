extends Attribute
class_name NoTouchAttribute

@onready var parent := get_parent() as CollisionObject2D


func _ready() -> void:
	for shape_owner in parent.get_shape_owners():
		parent.shape_owner_set_disabled(shape_owner, true)


func _exit_tree() -> void:
	for shape_owner in parent.get_shape_owners():
		parent.shape_owner_set_disabled(shape_owner, false)
