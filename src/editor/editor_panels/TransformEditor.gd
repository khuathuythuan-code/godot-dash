class_name TransformEditor
extends VBoxContainer

@export var edit_handler: EditHandler
@export var position_property: Vector2Property
@export var rotation_property: FloatSliderProperty
@export var scale_property: Vector2Property

var selection_size: int
var first_object: Node2D
var average_position: Vector2
var current_rotation: float
var pivot_relative_transforms: Dictionary[NodePath, Transform2D]
var same_scale: bool = true
var same_rotation: bool = true

@onready var current_selection := Selection.new()
@onready var parent: Node = get_parent()


func update_pivot_relative_transform() -> void:
	for collision_object in current_selection.to_array():
		var pivot_relative_transform: Transform2D = collision_object.global_transform
		pivot_relative_transform.origin -= edit_handler.selection_pivot
		pivot_relative_transforms[Editor.root.level.get_path_to(collision_object)] = pivot_relative_transform


func _on_edit_handler_selection_changed(selection: Selection) -> void:
	current_selection = selection
	if selection.is_empty():
		return
	first_object = current_selection.first()
	selection_size = selection.size()
	edit_handler.update_pivot()
	update_pivot_relative_transform()

	rotation_property.set_input_state(true)
	scale_property.set_input_state(true)

	if selection_size == 1:
		average_position = LevelManager.current_level.to_local(current_selection.first().global_position)
		current_rotation = first_object.global_rotation_degrees
		scale_property.set_value_no_signal(first_object.scale)
		position_property.set_value_no_signal((average_position / Constants.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))
		rotation_property.set_value_no_signal(current_rotation)
		same_scale = true
		same_rotation = true

		if current_selection.first() is Player:
			rotation_property.set_input_state(false)
			scale_property.set_input_state(false)
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
	position_property.set_value_no_signal((average_position / Constants.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))

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
	average_position += distance * Constants.CELL_SIZE
	position_property.set_value_no_signal((average_position / Constants.CELL_SIZE + Vector2(0, 0.5)) * Vector2(1, -1))


func _on_edit_handler_rotated_selection_degrees(angle_degrees: float) -> void:
	current_rotation += angle_degrees
	rotation_property.set_value_no_signal(current_rotation)


func _on_edit_handler_resized_selection(new_scale: Vector2) -> void:
	scale_property.set_value_no_signal(new_scale)


func _on_position_value_changed(new_position: Vector2) -> void:
	var distance := Vector2(new_position.x, -new_position.y - 0.5) - average_position / Constants.CELL_SIZE
	edit_handler.move_selection(distance)
	# No need to update the relative transforms since the pivot and objects move the same amount


func _on_rotation_value_changed(new_rotation: float) -> void:
	edit_handler.rotate_selection(new_rotation - current_rotation, true)
	current_rotation = new_rotation
	update_pivot_relative_transform()
	LevelManager.player.rotation_degrees = 0


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


func _on_rotation_interaction_ended(new_rotation: float, previous_rotation: float) -> void:
	edit_handler.rotate_selection(previous_rotation - current_rotation, true)
	edit_handler.rotate_selection(new_rotation - previous_rotation, false)
	current_rotation = new_rotation
	update_pivot_relative_transform()
	LevelManager.player.rotation_degrees = 0
