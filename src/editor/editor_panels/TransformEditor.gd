extends VBoxContainer

@export var z_index_node: FloatProperty
@export var scale_node: Vector2Property
@export var position_node: Vector2Property
@export var rotation_node: FloatProperty
@onready var parent: Node = get_parent()
var current_selection: Array[Node2D]
var selection_size: int
var first_object: Node2D
var average_position: Vector2
var same_scale: bool = true
var same_rotation: bool = true


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	current_selection = selection
	if selection.is_empty():
		return
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
		same_scale = true
		same_rotation = true
		current_selection.map(func(object): average_position = object.position)
		return

	var scales: Array[Vector2]
	current_selection.map(func(object): scales.append(object.scale))
	same_scale = true
	var first_value = scales[0]
	@warning_ignore("shadowed_variable_base_class")
	for scale in scales:
		if scale != first_value:
			same_scale = false
			break
	if same_scale:
		scale_node.set_value_no_signal(scales[0])
	else:
		scale_node.set_value_no_signal(Vector2(1, 1))

	var positions: Array[Vector2]
	current_selection.map(func(object): positions.append(object.position))
	average_position = Vector2.ZERO
	@warning_ignore("shadowed_variable_base_class")
	for position in positions:
		average_position += position
	average_position /= selection_size
	position_node.set_value_no_signal((average_position / LevelManager.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))

	var rotations: Array[float]
	current_selection.map(func(object): rotations.append(object.rotation_degrees))
	same_rotation = true
	first_value = rotations[0]
	@warning_ignore("shadowed_variable_base_class")
	for rotation in rotations:
		if rotation != first_value:
			same_rotation = false
			break
	if same_rotation:
		rotation_node.set_value_no_signal(rotations[1])
	else:
		rotation_node.set_value_no_signal(0)


func _on_scale_value_changed(value: Vector2) -> void:
	var scale_object
	var unscale_object

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


func _on_position_value_changed(_value: Vector2) -> void:
	var value = Vector2(_value.x * LevelManager.CELL_SIZE, (-_value.y - 0.5) * LevelManager.CELL_SIZE) - average_position
	var move_object := func(_object: Node2D):
		_object.position += value
	var unmove_object := func(_object: Node2D):
		_object.position -= value

	Editor.root.level.version_history.create_action("Moved object " + str(_value) + " units")
	for object in current_selection:
		Editor.root.level.version_history.add_do_method(move_object.bind(object))
		Editor.root.level.version_history.add_undo_method(unmove_object.bind(object))
	Editor.root.level.version_history.commit_action()

func _on_rotation_value_changed(value: float) -> void:
	if selection_size == 1 or same_rotation:
		value -= current_selection[0].rotation_degrees

	var rotate_object := func(_object: Node2D):
		_object.rotation_degrees += value
	var unrotate_object := func(_object: Node2D):
		_object.rotation_degrees -= value

	Editor.root.level.version_history.create_action("Rotated object " + str(value) + "°")
	for object in current_selection:
		Editor.root.level.version_history.add_do_method(rotate_object.bind(object))
		Editor.root.level.version_history.add_undo_method(unrotate_object.bind(object))
	Editor.root.level.version_history.commit_action()


func _set_z_index(_value: float):
	var value: int = int(_value)
	var move_object := func(_object: Node2D):
		_object.z_index = value
	var unmove_object := func(_object: Node2D, last_z_index):
		_object.z_index = last_z_index
	
	Editor.root.level.version_history.create_action("Changed object z index to " + str(value))
	for object in current_selection:
		Editor.root.level.version_history.add_do_method(move_object.bind(object))
		Editor.root.level.version_history.add_undo_method(unmove_object.bind(object, object.z_index))
	Editor.root.level.version_history.commit_action()
