extends Node
class_name EditHandler

signal selection_zone_changed(new_zone: Rect2)
signal selection_changed(selection: Array[Node2D])
signal clipboard_changed(clipboard: Array[NodePath])
signal rotated_object_degrees(rotation_degrees: float)

enum TransformPivot {
	MEDIAN_POINT,
	INDIVIDUAL_ORIGINS,
}

@export var gizmo_layer: CanvasLayer
@export var keychord_display: Label
@export var transform_pivot_button: OptionButton

var level: Level
var selection: Array[Node2D]
var clipboard: Array[NodePath]
var clipboard_camera_position: Vector2
var object_move_cooldown: float
var placed_objects_collider: Area2D
var editor_mode: TabContainer
var selection_index := 0
var cursor_position_snapped: Vector2
var previous_cursor_position_snapped: Vector2
var selection_pivot: Vector2
var gizmo: Gizmo


func _ready() -> void:
	_reset_selection_zone(true)
	var update_global_clipboard := func(new_clipboard): Editor.clipboard = new_clipboard
	clipboard_changed.connect(update_global_clipboard)


func _physics_process(delta: float) -> void:
	if LevelManager.level_playing:
		return
	if object_move_cooldown > 0:
		object_move_cooldown -= delta
	cursor_position_snapped = level.get_local_mouse_position().snapped(Vector2.ONE*128)
	if cursor_position_snapped != previous_cursor_position_snapped:
		selection_index = 0
	var is_already_swiping_selection: bool = $SelectionZone/Hitbox.shape.size != Vector2.ZERO
	if Input.is_action_just_pressed(&"editor_select_all", true) and not Editor.is_text_input_focused():
		select_all()

	var gizmo_in_use: bool = gizmo and (gizmo.is_enabled() or gizmo.any_handle_hovered())
	if is_already_swiping_selection or get_viewport().gui_get_hovered_control() == Editor.viewport:
		if editor_mode.get_current_tab_control().name == "Edit" and not gizmo_in_use and (not Config.is_touch_screen or gizmo == null):
			_update_selection()
		var can_use_actions: bool = (
				not selection.is_empty() and not (
					Input.is_action_pressed(&"editor_save", true)
					or Input.is_action_pressed(&"editor_save_as", true)
					or Input.is_action_pressed(&"editor_new_level", true)
					or Input.is_action_pressed(&"editor_import_level", true)
					or Input.is_action_pressed(&"editor_export_level", true)
					or any_gizmo_is_open()
				)
		)
		if can_use_actions:
			if Input.is_action_just_pressed(&"editor_deselect", true):
				clear_selection()
			if Input.is_action_just_pressed(&"editor_delete", true):
				delete_selection()
			if Input.is_action_just_pressed(&"editor_duplicate", true):
				duplicate_selection()
				object_move_cooldown = 5
			if Input.is_action_just_pressed(&"ui_copy", true):
				copy_selection()
			if Input.is_action_just_pressed(&"ui_paste", true):
				paste_selection()
				object_move_cooldown = 5
			if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")\
			and object_move_cooldown <= 0 and not Input.is_action_pressed(&"editor_select_all")\
			and not Input.is_action_pressed(&"editor_increase_z_index") and not Input.is_action_pressed(&"editor_decrease_z_index"):
				var move_vector: Vector2
				move_vector.x = Input.get_axis(&"ui_left", &"ui_right")
				move_vector.y = Input.get_axis(&"ui_up", &"ui_down")
				var move_multiplier := 1.0
				if Input.is_key_pressed(KEY_SHIFT):
					move_multiplier = 0.5
				selection.map(func(object): object.global_position += move_vector * LevelManager.CELL_SIZE * move_multiplier)
				object_move_cooldown = 0.2
			if Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45") and object_move_cooldown <= 0:
				_update_pivot()
				_rotate_selection(Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45") * 45.0)
				rotated_object_degrees.emit(Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45") * 45.0)
				object_move_cooldown = 0.2
			if Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90") and object_move_cooldown <= 0:
				_update_pivot()
				_rotate_selection(Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90") * 90.0)
				rotated_object_degrees.emit(Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90") * 90.0)
				object_move_cooldown = 0.2
			if Input.is_action_just_pressed(&"editor_flip_h", true):
				_flip_selection(Vector2.AXIS_X)
			if Input.is_action_just_pressed(&"editor_flip_v", true):
				_flip_selection(Vector2.AXIS_Y)
			if Input.is_action_just_pressed(&"editor_rotate_free", true):
				_on_rotate_free_pressed()
			elif Input.is_action_just_pressed(&"editor_quick_rotate_free", true):
				_on_rotate_free_pressed(true)
			if Input.is_action_just_pressed(&"editor_scale", true):
				_on_scale_pressed()
			elif Input.is_action_just_pressed(&"editor_quick_scale", true):
				_on_scale_pressed(true)
			if Input.is_action_just_pressed(&"editor_increase_z_index"):
				selection.map(increase_z_index)
				object_move_cooldown = 0.0
			if Input.is_action_just_pressed(&"editor_decrease_z_index"):
				selection.map(decrease_z_index)
				object_move_cooldown = 0.0
		if not (Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
				or Input.get_axis(&"editor_rotate_-45", &"editor_rotate_45")
				or Input.get_axis(&"editor_rotate_-90", &"editor_rotate_90")):
			object_move_cooldown = 0.0
		if Input.is_action_just_released(&"editor_add") and (!Config.is_touch_screen or gizmo == null):
			selection.map(add_selection_highlight)
			_reset_selection_zone()
	previous_cursor_position_snapped = cursor_position_snapped


func increase_z_index(object: Node):
	if object.z_index < 4096:
		object.z_index += 1
		return
	Toasts.warning("Maximum z-index is 4096")


func decrease_z_index(object: Node):
	if object.z_index > -100:
		object.z_index -= 1
		return
	Toasts.warning("Minimum z-index is -100")


func _update_selection() -> void:
	if get_viewport().gui_get_hovered_control() == Editor.viewport and Input.is_action_just_pressed(&"editor_add", false):
		if not Input.is_action_just_pressed(&"editor_add_swipe", true) \
				and not Input.is_action_just_pressed(&"editor_selection_remove", true):
			for object in selection:
				remove_selection_highlight(object)
			selection.clear()
			selection_index += 1
			selection_changed.emit(selection)
		_reset_selection_zone(false)
		if placed_objects_collider.has_overlapping_areas() and not (Input.is_action_just_pressed(&"editor_add_swipe", false) or Input.is_action_just_pressed(&"editor_selection_remove", false)):
			selection = [
				get_object_parent(
					placed_objects_collider.get_overlapping_areas()[
						selection_index%len(placed_objects_collider.get_overlapping_areas())
					]
				)
			]
			selection_changed.emit(selection)
	if Input.is_action_pressed(&"editor_selection_remove", false) or Input.is_action_pressed(&"editor_add", false):
		_swipe_selection_zone()
	var selection_buffer := Array($SelectionZone.get_overlapping_areas().map(get_object_parent), TYPE_OBJECT, "Node2D", null)
	if Input.is_action_just_released(&"editor_selection_remove", true):
		ArrayUtils.intersect(selection, selection_buffer, TYPE_OBJECT, "Node2D").map(remove_selection_highlight)
		selection = ArrayUtils.difference(selection, selection_buffer, TYPE_OBJECT, "Node2D")
		selection_changed.emit(selection)
	elif (Input.is_action_just_released(&"editor_add", true) and $SelectionZone/Hitbox.shape.size > Vector2.ONE * 2) or Input.is_action_just_released(&"editor_add_swipe", true):
		selection = ArrayUtils.union(selection, selection_buffer, TYPE_OBJECT, "Node2D")
		selection_changed.emit(selection)
	selection.erase(level)


func _reset_selection_zone(unreachable: bool = true) -> void:
	$SelectionZone.position = Vector2.ONE * INF if unreachable else get_parent().get_local_mouse_position()
	$SelectionZone/Hitbox.shape.size = Vector2.ZERO
	$SelectionZone/Hitbox.position = Vector2.ZERO
	selection_zone_changed.emit(Rect2(Vector2.ZERO, Vector2.ZERO))


func _swipe_selection_zone() -> void:
	var mouse_position := get_parent().get_local_mouse_position() as Vector2
	var hitbox := $SelectionZone/Hitbox as CollisionShape2D
	
	hitbox.shape.size = abs(mouse_position - $SelectionZone.position)
	# Right Down
	if mouse_position.x >= $SelectionZone.position.x and mouse_position.y >= $SelectionZone.position.y:
		hitbox.position = hitbox.shape.size * 0.5
	# Right Up
	elif mouse_position.x >= $SelectionZone.position.x and mouse_position.y < $SelectionZone.position.y:
		hitbox.position.x = hitbox.shape.size.x * 0.5
		hitbox.position.y = -hitbox.shape.size.y * 0.5
	# Left Down
	elif mouse_position.x < $SelectionZone.position.x and mouse_position.y >= $SelectionZone.position.y:
		hitbox.position.x = -hitbox.shape.size.x * 0.5
		hitbox.position.y = hitbox.shape.size.y * 0.5
	# Left Up
	elif mouse_position.x < $SelectionZone.position.x and mouse_position.y < $SelectionZone.position.y:
		hitbox.position = -hitbox.shape.size * 0.5
	
	selection_zone_changed.emit(Rect2($SelectionZone/Hitbox.position - $SelectionZone/Hitbox.shape.size * 0.5, $SelectionZone/Hitbox.shape.size))


func _clone(object: Node) -> Node:
	remove_selection_highlight(object)
	NodeUtils.change_owner_recursive(object, object)
	var packer := PackedScene.new()
	packer.pack(object)
	var clone := packer.instantiate()
	object.get_parent().add_child(clone, true)
	clone.owner = object.owner
	add_selection_highlight(clone)
	NodeUtils.change_owner_recursive(object, level)
	NodeUtils.change_owner_recursive(clone, level)
	return clone


func duplicate_selection() -> void:
	selection = Array(selection.map(_clone), TYPE_OBJECT, "Node2D", null)
	for object in selection:
		var hsv_watcher: HSVWatcher = NodeUtils.get_child_of_type(object, HSVWatcher)
		hsv_watcher.selection_highlight = HSVWatcher.SelectionHighlight.DUPLICATE
	selection_changed.emit(selection)


func copy_selection() -> void:
	# Using map returns an array filled with `null` instead of NodePaths.
	# Go figure.
	clipboard.clear()
	for object in selection:
		clipboard.append(level.get_path_to(object))
	clipboard_camera_position = get_viewport().get_camera_2d().get_screen_center_position()
	clipboard_changed.emit(clipboard)
	Toasts.new_toast("Selection copied!")


func paste_selection() -> void:
	selection.map(remove_selection_highlight)
	selection.clear()
	for path in clipboard:
		selection.append(level.get_node(path))
	selection = Array(selection.map(_clone), TYPE_OBJECT, "Node2D", null)
	selection_changed.emit(selection)
	var move_objects_to_new_screen_center = func(object):
		object.global_position += (get_viewport().get_camera_2d().get_screen_center_position() - clipboard_camera_position).snappedf(LevelManager.CELL_SIZE)
	selection.map(move_objects_to_new_screen_center)


func delete_selection() -> void:
	selection.map(NodeUtils.free_node)
	selection.clear()
	rotated_object_degrees.emit(0.0) # Reset
	_reset_selection_zone()
	selection_changed.emit(selection)


func clear_selection() -> void:
	selection.map(remove_selection_highlight)
	selection.clear()
	_reset_selection_zone()
	selection_changed.emit(selection)


func select_all() -> void:
	clear_selection()
	await get_tree().process_frame
	var only_node_2ds := func(object): return object is Node2D
	selection.assign(level.get_children().duplicate().filter(only_node_2ds))
	selection.map(add_selection_highlight)
	selection_changed.emit(selection)


func remove_gizmo(_selection = null) -> void:
	if not gizmo:
		return
	gizmo.remove_gizmo()
	if selection_changed.is_connected(remove_gizmo):
		selection_changed.disconnect(remove_gizmo)
	if get_viewport().gui_focus_changed.is_connected(remove_gizmo):
		get_viewport().gui_focus_changed.disconnect(remove_gizmo)
	gizmo = null


func any_gizmo_is_open() -> bool:
	return gizmo != null


func _update_pivot() -> void:
	if selection.is_empty():
		return
	var group_parents := selection.filter(func(object): return object.has_meta("group_parent"))
	if not group_parents.is_empty():
		selection_pivot = group_parents[0].global_position
	else:
		# Take the mean of the position of all objects
		var object_positions := selection.map(func(object): return object.global_position)
		selection_pivot = ArrayUtils.transform(object_positions, ArrayUtils.Transformation.MEAN, true)


func _flip_selection(axis: int):
	if selection.is_empty():
		return
	match axis:
		Vector2.AXIS_X:
			for object in selection:
				object.scale.x *= -1
				var position_relative_to_pivot: Vector2 = object.global_position - selection_pivot
				object.global_position.x = selection_pivot.x - position_relative_to_pivot.x
		Vector2.AXIS_Y:
			for object in selection:
				object.scale.y *= -1
				var position_relative_to_pivot: Vector2 = object.global_position - selection_pivot
				object.global_position.y = selection_pivot.y - position_relative_to_pivot.y


func _on_place_handler_object_deleted(object:Node) -> void:
	if object in selection:
		selection.erase(object)
		selection_changed.emit(selection)


func _on_move_controls_direction_pressed(direction: Vector2, step: float) -> void:
	if selection.is_empty():
		return
	selection.map(func(object): object.position += LevelManager.CELL_SIZE * direction * step)


func _on_rotate_left_90_pressed() -> void:
		_update_pivot()
		_rotate_selection(-90)


func _on_rotate_right_90_pressed() -> void:
	_update_pivot()
	_rotate_selection(90)


func _on_rotate_left_45_pressed() -> void:
	_update_pivot()
	_rotate_selection(-45)


func _on_rotate_right_45_pressed() -> void:
	_update_pivot()
	_rotate_selection(45)


func _on_flip_h_pressed() -> void:
	_update_pivot()
	_flip_selection(Vector2.AXIS_X)


func _on_flip_v_pressed() -> void:
	_update_pivot()
	_flip_selection(Vector2.AXIS_Y)


func _on_rotate_free_pressed(quick: bool = false) -> void:
	if selection.is_empty():
		return
	_update_pivot()
	gizmo = RotateGizmo.new()
	get_viewport().gui_focus_changed.disconnect(remove_gizmo)
	if quick:
		gizmo.quick(keychord_display, "Rotating", "°", true)
		get_viewport().gui_focus_changed.connect(remove_gizmo)
	gizmo_layer.add_child(gizmo)
	gizmo.global_position = selection_pivot
	gizmo.angle_changed.connect(_rotate_selection)
	selection_changed.connect(remove_gizmo)


func _on_scale_pressed(quick: bool = false) -> void:
	if selection.is_empty():
		return
	_update_pivot()
	if gizmo != null:
		gizmo.queue_free()
	var selection_collision_objects: Array[CollisionObject2D]
	selection_collision_objects.assign(
			selection
			.filter(func(object: Node2D): return object is CollisionObject2D)
	)

	var first_object_rotation: float = selection[0].global_rotation
	var mean_objects_rotation: float = first_object_rotation
	#var same_rotation := func(object: CollisionObject2D, rotation: float): return is_zero_approx(fposmod(object.global_rotation - rotation, PI/2))
	#mean_objects_rotation = first_object_rotation if selection_collision_objects.all(same_rotation.bind(first_object_rotation)) else 0.0
	var gizmo_center: Vector2 = ArrayUtils.transform(
			selection.map(func(object: Node2D): return object.global_position.rotated(-mean_objects_rotation)),
			ArrayUtils.Transformation.MEAN,
			true
	).rotated(mean_objects_rotation)
	selection_pivot = gizmo_center

	var pivot_relative_transforms: Dictionary[Node2D, Transform2D]
	for collision_object in selection_collision_objects:
		var pivot_relative_transform: Transform2D = collision_object.global_transform
		pivot_relative_transform.origin -= selection_pivot
		pivot_relative_transforms[collision_object] = pivot_relative_transform

	selection_collision_objects.assign(selection_collision_objects.map(get_object_selection_collider))
	var selection_bounding_box: Transform2D = BoundingBox.new(selection_collision_objects, selection_pivot, mean_objects_rotation).as_transform()
	gizmo = ScaleGizmo.new(selection_bounding_box)
	if get_viewport().gui_focus_changed.is_connected(remove_gizmo):
		get_viewport().gui_focus_changed.disconnect(remove_gizmo)
	if quick:
		gizmo.quick(keychord_display, "Scaling", "×", false)
		get_viewport().gui_focus_changed.connect(remove_gizmo)
	gizmo.global_position = gizmo_center
	gizmo.rotation = mean_objects_rotation
	gizmo_layer.add_child(gizmo)
	gizmo.scale_changed.connect(_scale_selection.bind(pivot_relative_transforms))
	NodeUtils.connect_once(selection_changed, remove_gizmo)


func _rotate_selection(angle: float) -> void:
	if selection.is_empty():
		return
	for object in selection:
		object.global_rotation_degrees += angle
		if transform_pivot_button.selected != TransformPivot.INDIVIDUAL_ORIGINS:
			var position_relative_to_pivot: Vector2 = object.global_position - selection_pivot
			var position_delta := position_relative_to_pivot.rotated(deg_to_rad(angle)) - position_relative_to_pivot
			object.global_position += position_delta


func _scale_selection(
			position: Vector2,
			transform: Transform2D,
			rotation: float,
			is_global: bool,
			pivot_relative_transforms: Dictionary[Node2D, Transform2D]
		) -> void:
	if selection.is_empty():
		return
	selection_pivot = position
	if is_global:
		selection.map.call_deferred(scale_transform.bind(pivot_relative_transforms, position, transform))
	else:
		selection.map.call_deferred(scale_transform_local.bind(pivot_relative_transforms, position, transform, rotation))


static func scale_transform(
			object: Node2D,
			pivot_relative_transforms: Dictionary[Node2D, Transform2D],
			pivot: Vector2,
			transform: Transform2D,
		):
	var pivot_relative_transform: Transform2D = pivot_relative_transforms[object]
	object.global_transform = (transform * pivot_relative_transform).translated(pivot)


static func scale_transform_local(
			object: Node2D,
			pivot_relative_transforms: Dictionary[Node2D, Transform2D],
			pivot: Vector2,
			transform: Transform2D,
			rotation: float,
		):
	var pivot_relative_transform: Transform2D = pivot_relative_transforms[object]
	object.global_transform = (
		(transform * pivot_relative_transform.rotated(-rotation))
		.rotated(rotation)
		.translated(pivot)
	)


static func add_selection_highlight(object: Node2D) -> void:
	var hsv_watcher: HSVWatcher = NodeUtils.get_child_of_type(object, HSVWatcher)
	hsv_watcher.selection_highlight = HSVWatcher.SelectionHighlight.NORMAL


static func remove_selection_highlight(object: Node2D) -> void:
	var hsv_watcher: HSVWatcher = NodeUtils.get_child_of_type(object, HSVWatcher)
	hsv_watcher.selection_highlight = HSVWatcher.SelectionHighlight.NONE


static func get_object_parent(object: Node) -> Node2D:
	if object is EditorSelectionCollider:
		return object.get_parent()
	else:
		return object


static func get_object_selection_collider(object: CollisionObject2D) -> CollisionObject2D:
	var selection_collider: EditorSelectionCollider = NodeUtils.get_child_of_type(object, EditorSelectionCollider)
	return selection_collider if selection_collider else object
