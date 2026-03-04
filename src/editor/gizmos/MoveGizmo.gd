extends Gizmo

class_name MoveGizmo

signal position_changed(position: Vector2)

var initial_mouse_position: Vector2
var initial_global_position: Vector2
var transform_initial_global_position: Vector2
var tween: Tween
var used_axis: int = Constants.AxisBitflag.NONE


func _ready() -> void:
	if get_viewport().get_camera_2d() is MapCamera2D:
		get_viewport().get_camera_2d().drag = false
	state = State.ENABLED
	initial_mouse_position = get_global_mouse_position()
	initial_global_position = global_position
	Editor.shortcut_blocker = self
	get_viewport().gui_release_focus()
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, ^"gizmo_scale", 1.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	var horizontal_axis_hovered: bool = is_horizontal_axis_hovered()
	var vertical_axis_hovered: bool = is_vertical_axis_hovered()
	var constrained_axis: Constants.Axis = get_constrained_axis()
	if (horizontal_axis_hovered and vertical_axis_hovered) or used_axis == Constants.AxisBitflag.X | Constants.AxisBitflag.Y:
		Editor.viewport.override_cursor_shape(CursorShape.CURSOR_MOVE)
	elif horizontal_axis_hovered or used_axis == Constants.AxisBitflag.X:
		Editor.viewport.override_cursor_shape(CursorShape.CURSOR_HSPLIT)
	elif vertical_axis_hovered or used_axis == Constants.AxisBitflag.Y:
		Editor.viewport.override_cursor_shape(CursorShape.CURSOR_VSPLIT)
	else:
		Editor.viewport.remove_cursor_shape_override()
	if get_viewport().get_camera_2d():
		scale.x = 1 / get_viewport().get_camera_2d().zoom.x
		scale.y = 1 / get_viewport().get_camera_2d().zoom.y
		scale *= gizmo_scale
	else:
		scale = Vector2.ONE * gizmo_scale
	queue_redraw()
	if is_removing:
		return
	var previous_global_position: Vector2 = global_position
	if is_quick:
		if constrained_axis == Constants.Axis.X:
			used_axis = Constants.AxisBitflag.X
			global_position.y = initial_global_position.y
			global_position.x = initial_global_position.x + get_global_mouse_position().x - initial_mouse_position.x
		elif constrained_axis == Constants.Axis.Y:
			used_axis = Constants.AxisBitflag.Y
			global_position.x = initial_global_position.x
			global_position.y = initial_global_position.y + get_global_mouse_position().y - initial_mouse_position.y
		else:
			used_axis = Constants.AxisBitflag.X | Constants.AxisBitflag.Y
			global_position = initial_global_position + get_global_mouse_position() - initial_mouse_position
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and used_axis == Constants.AxisBitflag.NONE:
			if horizontal_axis_hovered:
				used_axis |= Constants.AxisBitflag.X
			if vertical_axis_hovered:
				used_axis |= Constants.AxisBitflag.Y
			initial_mouse_position = get_global_mouse_position()
			transform_initial_global_position = global_position

		if used_axis & Constants.AxisBitflag.X:
			global_position.x = transform_initial_global_position.x + get_global_mouse_position().x - initial_mouse_position.x
		if used_axis & Constants.AxisBitflag.Y:
			global_position.y = transform_initial_global_position.y + get_global_mouse_position().y - initial_mouse_position.y

		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			used_axis = Constants.AxisBitflag.NONE
	var is_gizmo_in_use: bool = used_axis != Constants.AxisBitflag.NONE
	if is_snapping() and is_gizmo_in_use:
		global_position = (global_position - initial_global_position).snappedf(Constants.CELL_SIZE) + initial_global_position
	position_changed.emit((global_position - previous_global_position) / Constants.CELL_SIZE)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and not any_handle_hovered():
		remove_gizmo()


func _draw() -> void:
	draw_gizmo(Color.BLACK, true)
	draw_gizmo(Color.WHITE)


func draw_gizmo(color: Color, outline: bool = false) -> void:
	if outline:
		color.a /= 2
	var horizontal_axis_color: Color = color
	if is_horizontal_axis_hovered():
		horizontal_axis_color.a /= 2
	var vertical_axis_color: Color = color
	if is_vertical_axis_hovered():
		vertical_axis_color.a /= 2
	var length: int = 102 if outline else 100
	var width: int = 5 if outline else 1
	draw_line(Vector2(length, 0), Vector2(-length, 0), horizontal_axis_color, width, true)
	draw_line(Vector2(0, length), Vector2(0, -length), vertical_axis_color, width, true)
	draw_circle(Vector2.ZERO, width + 1.5 if outline else width + 3.0, color, true, -1, true)
	for direction in [0, 90, 180, 270]:
		var points: PackedVector2Array = [Vector2(103.5, -11.5), Vector2(115, 0), Vector2(103.5, 11.5)] if outline else [Vector2(105, -10), Vector2(115, 0), Vector2(105, 10)]
		for point in points:
			points.set(points.find(point), point.rotated(deg_to_rad(direction)))
		if direction % 180 == 0:
			draw_polyline(points, horizontal_axis_color, width, true)
		else:
			draw_polyline(points, vertical_axis_color, width, true)
	var constrained_axis: Constants.Axis = get_constrained_axis()
	if constrained_axis == Constants.Axis.X:
		horizontal_axis_color.a /= 2
		draw_line(Vector2(2000, 0), Vector2(-2000, 0), horizontal_axis_color, width, true)
	elif constrained_axis == Constants.Axis.Y:
		vertical_axis_color.a /= 2
		draw_line(Vector2(0, 2000), Vector2(0, -2000), vertical_axis_color, width, true)


func remove_gizmo(reset: bool = false) -> void:
	if is_removing:
		return
	if get_viewport().get_camera_2d() is MapCamera2D:
		get_viewport().get_camera_2d().drag = true
	Editor.viewport.remove_cursor_shape_override()
	is_removing = true
	state = State.DISABLED
	used_axis = Constants.AxisBitflag.NONE
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel()
	var do_reset_position := func(_position: Vector2):
		var position_delta = _position - global_position
		global_position += position_delta
		position_changed.emit(position_delta / Constants.CELL_SIZE)
	tween.tween_property(self, ^"gizmo_scale", 0.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, ^"modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if reset:
		tween.tween_method(do_reset_position, global_position, initial_global_position, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	else:
		var distance_from_start: Vector2 = initial_global_position - global_position
		position_changed.emit(distance_from_start / Constants.CELL_SIZE)
		confirmed.emit(-distance_from_start / Constants.CELL_SIZE)
	await tween.finished
	queue_free()


func is_enabled() -> bool:
	return state != State.DISABLED


func is_horizontal_axis_hovered() -> bool:
	var horizontal_axis_rect: Rect2 = Rect2(global_position - Vector2(125, 12.5) / get_viewport().get_camera_2d().zoom, Vector2(250, 25) / get_viewport().get_camera_2d().zoom)
	return horizontal_axis_rect.has_point(get_global_mouse_position()) and not is_quick


func is_vertical_axis_hovered() -> bool:
	var vertical_axis_rect: Rect2 = Rect2(global_position - Vector2(12.5, 125) / get_viewport().get_camera_2d().zoom, Vector2(25, 250) / get_viewport().get_camera_2d().zoom)
	return vertical_axis_rect.has_point(get_global_mouse_position()) and not is_quick


func any_handle_hovered() -> bool:
	return is_horizontal_axis_hovered() or is_vertical_axis_hovered()


func is_snapping() -> bool:
	return Input.is_key_pressed(KEY_CTRL)


func get_constrained_axis() -> Constants.Axis:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or abs(abs(global_position.x - initial_global_position.x) - abs(global_position.y - initial_global_position.y)) < 50 / get_viewport().get_camera_2d().zoom.x:
		return Constants.Axis.BOTH
	elif abs(global_position.x - initial_global_position.x) > abs(global_position.y - initial_global_position.y):
		return Constants.Axis.X
	else:
		return Constants.Axis.Y


func _quick() -> void:
	pass
