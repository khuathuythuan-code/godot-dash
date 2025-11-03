extends VBoxContainer
class_name TransformEditor

@export var edit_handler: EditHandler
@export var z_index_node: FloatProperty
@export var scale_node: Vector2Property
@export var position_node: Vector2Property
@export var rotation_node: FloatProperty
@onready var parent: Node = get_parent()

var current_selection: Array[Node2D]
var selection_size: int
var first_object: Node2D
var average_position: Vector2
var previous_rotation: float
var same_scale: bool = true
var same_rotation: bool = true


func _process(_delta: float) -> void:
	if current_selection.is_empty():
		return
	z_index_node.set_value_no_signal(float(first_object.z_index))
	if selection_size == 1:
		scale_node.set_value_no_signal(first_object.scale)
		position_node.set_value_no_signal((first_object.position / LevelManager.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))
		rotation_node.set_value_no_signal(first_object.rotation_degrees)
		same_scale = true
		same_rotation = true
		current_selection.map(func(object): average_position = object.position)
		return

	var object_scales: Array[Vector2]
	object_scales.assign(current_selection.map(func(object: Node2D): return object.scale))
	same_scale = true
	var first_value = object_scales[0]
	for object_scale: Vector2 in object_scales:
		if object_scale != first_value:
			same_scale = false
			break
	if same_scale:
		scale_node.set_value_no_signal(object_scales[0])
	else:
		scale_node.set_value_no_signal(Vector2(1, 1))

	var object_positions: Array[Vector2]
	object_positions.assign(current_selection.map(func(object: Node2D): return object.position))
	average_position = Vector2.ZERO
	for object_position: Vector2 in object_positions:
		average_position += object_position
	average_position /= selection_size
	position_node.set_value_no_signal((average_position / LevelManager.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))

	var object_rotations: Array[float]
	object_rotations.assign(current_selection.map(func(object: Node2D): return object.rotation_degrees))
	same_rotation = true
	first_value = object_rotations[0]
	for object_rotation: float in object_rotations:
		if object_rotation != first_value:
			same_rotation = false
			break
	if same_rotation:
		rotation_node.set_value_no_signal(object_rotations[1])
		previous_rotation = object_rotations[1]
	else:
		rotation_node.set_value_no_signal(0.0)
		previous_rotation = 0.0


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	current_selection = selection
	if selection.is_empty():
		return
	first_object = current_selection.get(0)
	selection_size = selection.size()


func _on_scale_value_changed(value: Vector2) -> void:
	var scale_object: Callable
	var unscale_object: Callable

	if selection_size == 1 or same_scale:
		value -= current_selection[0].scale
		scale_object = func(_object: Node2D):
			_object.scale += value
		unscale_object = func(_object: Node2D):
			_object.scale -= value
	else:
		scale_object = func(_object: Node2D):
			_object.scale *= value
		unscale_object = func(_object: Node2D):
			_object.scale /= value
	Editor.root.level.version_history.create_action("Scaled object " + str(value))
	for object in current_selection:
		Editor.root.level.version_history.add_do_method(scale_object.bind(object))
		Editor.root.level.version_history.add_undo_method(unscale_object.bind(object))
	Editor.root.level.version_history.commit_action()


func _on_position_value_changed(new_position: Vector2) -> void:
	var distance := Vector2(new_position.x * LevelManager.CELL_SIZE, (-new_position.y - 0.5) * LevelManager.CELL_SIZE) - average_position
	edit_handler.move_objects(distance, current_selection)


func _on_rotation_value_changed(new_rotation: float) -> void:
	edit_handler._update_pivot()
	edit_handler._rotate_selection(new_rotation - previous_rotation)
	previous_rotation = new_rotation


func _set_z_index(_value: float):
	var new_z_index: int = int(_value)
	var move_object := func(_object: Node2D):
		_object.z_index = new_z_index
	var unmove_object := func(_object: Node2D, last_z_index):
		_object.z_index = last_z_index
	
	Editor.root.level.version_history.create_action("Changed object z index to " + str(new_z_index))
	for object in current_selection:
		Editor.root.level.version_history.add_do_method(move_object.bind(object))
		Editor.root.level.version_history.add_undo_method(unmove_object.bind(object, object.z_index))
	Editor.root.level.version_history.commit_action()
