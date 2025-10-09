extends VBoxContainer

@export var z_index_node: FloatProperty
@onready var parent: Node = get_parent()


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		parent.hide()
		return
	parent.show()
	var first_object: Node2D = selection.get(0)
	if not first_object:
		return
	z_index_node.set_value(float(first_object.z_index))
