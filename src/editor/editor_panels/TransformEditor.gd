extends VBoxContainer

@export var z_index_node: FloatProperty
@export var scale_node: Vector2Property
@export var position_node: Vector2Property
@export var rotation_node: FloatProperty
@onready var parent: Node = get_parent()
var current_selection: Array[Node2D]
var first_object: Node2D


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	current_selection = selection
	if selection.is_empty():
		parent.hide()
		return
	parent.show()
	first_object = current_selection.get(0)
	_process(0)



func _process(_delta: float) -> void:
	if current_selection.is_empty():
		return
	z_index_node.set_value_no_signal(float(first_object.z_index))
	scale_node.set_value_no_signal(first_object.scale)
	position_node.set_value_no_signal((first_object.position / LevelManager.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))
	rotation_node.set_value_no_signal(first_object.rotation_degrees)
