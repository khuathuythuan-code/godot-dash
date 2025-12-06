extends VBoxContainer
class_name TransformEditor

@export var edit_handler: EditHandler
@export var position_property: Vector2Property
@export var rotation_property: FloatProperty
@export var scale_property: Vector2Property
@export var z_index_property: FloatProperty

var selection_size: int
var first_object: Node2D
var average_position: Vector2
var current_rotation: float
var pivot_relative_transforms: Dictionary[Node2D, Transform2D]
var same_scale: bool = true
var same_rotation: bool = true

@onready var current_selection := Selection.new()
@onready var parent: Node = get_parent()


func update_pivot_relative_transform() -> void:
	for collision_object in current_selection.to_array():
		var pivot_relative_transform: Transform2D = collision_object.global_transform
		pivot_relative_transform.origin -= edit_handler.selection_pivot
		pivot_relative_transforms[collision_object] = pivot_relative_transform


func _on_edit_handler_selection_changed(selection: Selection) -> void:
	current_selection = selection
	if selection.is_empty():
		return
	first_object = current_selection.first()
	selection_size = selection.size()
	edit_handler.update_pivot()
	update_pivot_relative_transform()

	z_index_property.set_value_no_signal(float(first_object.z_index))
	if selection_size == 1:
		scale_property.set_value_no_signal(first_object.scale)
		position_property.set_value_no_signal((first_object.position / LevelManager.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))
		rotation_property.set_value_no_signal(first_object.global_rotation_degrees)
		same_scale = true
		same_rotation = true
		current_rotation = first_object.global_rotation_degrees
		average_position = LevelManager.current_level.to_local(current_selection.first().global_position)
		return

	var object_scales: Array[Vector2]
	object_scales.assign(current_selection.map_generic(func(object: Node2D): return object.scale))
	same_scale = true
	var first_scale: Vector2 = object_scales[0]
	for object_scale: Vector2 in object_scales:
		if object_scale != first_scale:
			same_scale = false
			break
	if same_scale:
		scale_property.set_value_no_signal(object_scales[0])
	else:
		scale_property.set_value_no_signal(Vector2(1, 1))

	var object_positions: Array[Vector2]
	object_positions.assign(current_selection.map_generic(func(object: Node2D): return LevelManager.current_level.to_local(object.global_position)))
	average_position = ArrayUtils.transform(object_positions, ArrayUtils.Transformation.MEAN, true)
	position_property.set_value_no_signal((average_position / LevelManager.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))

	var object_rotations: Array[float]
	object_rotations.assign(current_selection.map_generic(func(object: Node2D): return object.rotation_degrees))
	same_rotation = true
	var first_rotation: float = object_rotations[0]
	for object_rotation: float in object_rotations:
		if object_rotation != first_rotation:
			same_rotation = false
			break
	if same_rotation:
		rotation_property.set_value_no_signal(object_rotations[1])
		current_rotation = object_rotations[1]
	else:
		rotation_property.set_value_no_signal(0.0)
		current_rotation = 0.0


func _on_edit_handler_moved_selection_cells(distance: Vector2) -> void:
	average_position += distance * LevelManager.CELL_SIZE
	position_property.set_value_no_signal((average_position / LevelManager.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))


func _on_edit_handler_rotated_selection_degrees(angle_degrees: float) -> void:
	current_rotation += angle_degrees
	rotation_property.set_value_no_signal(current_rotation)


func _on_edit_handler_resized_selection(new_scale: Vector2) -> void:
	scale_property.set_value_no_signal(new_scale)


func _on_edit_handler_z_index_changed(z_index_delta: int) -> void:
	z_index_property.set_value_no_signal(z_index_property.get_value() + z_index_delta)


func _on_position_value_changed(new_position: Vector2) -> void:
	var distance := Vector2(new_position.x, -new_position.y - 0.5) - average_position / LevelManager.CELL_SIZE
	edit_handler.move_selection(distance)
	# No need to update the relative transforms since the pivot and objects move the same amount


func _on_rotation_value_changed(new_rotation: float) -> void:
	edit_handler.rotate_selection(new_rotation - current_rotation, false)
	current_rotation = new_rotation
	update_pivot_relative_transform()


func _on_scale_value_changed(new_scale: Vector2) -> void:
	edit_handler.scale_selection(
		edit_handler.selection_pivot,
		Transform2D.IDENTITY.scaled(new_scale),
		deg_to_rad(current_rotation),
		false,
		pivot_relative_transforms,
		true,
		edit_handler.selection_pivot,
	)


func _set_z_index(new_z_index: int):
	var do_z_index_shift := func(_selection: Selection):
		for _object: Node2D in _selection.to_array():
			_object.z_index = new_z_index
	var undo_z_index_shift := func(_selection_to_z_index: Dictionary[Node2D, int]):
		for _object: Node2D in _selection_to_z_index:
			_object.z_index = _selection_to_z_index[_object]
	
	var selection_snapshot: Selection = current_selection.clone()
	var object_to_z_index := func(object: Node2D):
		return object.z_index
	var selection_to_z_index: Dictionary[Node2D, int]
	selection_to_z_index.assign(selection_snapshot.map_generic_dict(object_to_z_index))
	var version_history: VersionHistory = Editor.version_history
	version_history.create_action("Changed object z index to %s" % new_z_index)
	version_history.add_do_method(do_z_index_shift.bind(selection_snapshot))
	version_history.add_undo_method(undo_z_index_shift.bind(selection_to_z_index))
	version_history.commit_action()
