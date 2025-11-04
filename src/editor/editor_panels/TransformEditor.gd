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
var current_rotation: float
var pivot_relative_transforms: Dictionary[Node2D, Transform2D]
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
		current_rotation = object_rotations[1]
	else:
		rotation_node.set_value_no_signal(0.0)
		current_rotation = 0.0


func update_pivot_relative_transform() -> void:
	for collision_object in current_selection:
		var pivot_relative_transform: Transform2D = collision_object.global_transform
		pivot_relative_transform.origin -= edit_handler.selection_pivot
		pivot_relative_transforms[collision_object] = pivot_relative_transform


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	current_selection = selection
	if selection.is_empty():
		return
	first_object = current_selection.get(0)
	selection_size = selection.size()
	edit_handler.update_pivot()
	update_pivot_relative_transform()


func _on_scale_value_changed(new_scale: Vector2) -> void:
	edit_handler.scale_selection(
		edit_handler.selection_pivot,
		Transform2D.IDENTITY.scaled(new_scale),
		deg_to_rad(current_rotation),
		false,
		pivot_relative_transforms,
		true,
		edit_handler.selection_pivot
	)


func _on_position_value_changed(new_position: Vector2) -> void:
	var distance := Vector2(new_position.x, -new_position.y - 0.5) - average_position / LevelManager.CELL_SIZE
	edit_handler.selection_pivot += distance
	edit_handler.move_objects(distance, current_selection)
	update_pivot_relative_transform()


func _on_rotation_value_changed(new_rotation: float) -> void:
	edit_handler.rotate_selection(new_rotation - current_rotation)
	current_rotation = new_rotation
	update_pivot_relative_transform()


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
