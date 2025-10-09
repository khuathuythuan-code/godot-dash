extends VBoxContainer

@export var z_index_node: FloatProperty
@export var scale_node: Vector2Property
@export var position_node: Vector2Property
@export var rotation_node: FloatProperty
@onready var parent: Node = get_parent()
var current_selection: Array[Node2D]
var selection_size: int
var first_object: Node2D


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	current_selection = selection
	if selection.is_empty():
		parent.hide()
		return
	parent.show()
	first_object = current_selection.get(0)
	selection_size = selection.size()


func _process(_delta: float) -> void:
	if current_selection.is_empty():
		return
	z_index_node.set_value_no_signal(float(first_object.z_index))
	if selection_size == 1:
		scale_node.set_value_no_signal(first_object.scale)
		position_node.set_value_no_signal((first_object.position / LevelManager.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))
		rotation_node.set_value_no_signal(first_object.rotation_degrees)
		return
	var scales: Array[Vector2]
	current_selection.map(func(object): scales.append(object.scale))
	var same_scale: bool # always 1 when not all the same
	var first_value = scales[0]
	for value in scales:
		if value != first_value:
			same_scale = false
			break
	var positions: Array[Vector2]
	current_selection.map(func(object): scales.append(object.scale))
	var average_position: Vector2
	
	var same_rotation: bool # always 0 when not all the same
