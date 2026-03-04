extends Gizmo

class_name MoveGizmo

signal position_changed(position: Vector2)

var horizontal_axis_hovered: bool:
	get():
		return (Rect2(global_position - Vector2(125, 12.5) / get_viewport().get_camera_2d().zoom, Vector2(250, 25) / get_viewport().get_camera_2d().zoom).has_point(get_global_mouse_position()) or initial_horizontal_axis_position != 0) and not is_quick
var vertical_axis_hovered: bool:
	get():
		return (Rect2(global_position - Vector2(12.5, 125) / get_viewport().get_camera_2d().zoom, Vector2(25, 250) / get_viewport().get_camera_2d().zoom).has_point(get_global_mouse_position()) or initial_vertical_axis_position != 0) and not is_quick
var initial_horizontal_axis_position: float = 0
var initial_vertical_axis_position: float = 0
var initial_mouse_position: Vector2
var initial_position: Vector2
var tween: Tween
var snapping: bool:
	get():
		return Input.is_key_pressed(KEY_CTRL)


func _ready() -> void:
	state = State.ENABLED
	initial_mouse_position = get_global_mouse_position()
	initial_position = global_position
	Editor.shortcut_blocker = self
	get_viewport().gui_release_focus()
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, ^"gizmo_scale", 1.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	if horizontal_axis_hovered and vertical_axis_hovered:
		Editor.viewport.override_cursor_shape(CursorShape.CURSOR_MOVE)
	elif horizontal_axis_hovered:
		Editor.viewport.override_cursor_shape(CursorShape.CURSOR_HSPLIT)
	elif vertical_axis_hovered:
		Editor.viewport.override_cursor_shape(CursorShape.CURSOR_VSPLIT)
	else:
		Editor.viewport.remove_cursor_shape_override()
	if get_viewport().get_camera_2d() != null:
		scale.x = 1 / get_viewport().get_camera_2d().zoom.x
		scale.y = 1 / get_viewport().get_camera_2d().zoom.y
		scale *= gizmo_scale
	else:
		scale = Vector2.ONE * gizmo_scale
	queue_redraw()
	if is_removing:
		return
	var _global_position = global_position
	if is_quick:
		global_position = initial_position + get_global_mouse_position() - initial_mouse_position	
	else:
		if horizontal_axis_hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and initial_horizontal_axis_position == 0:
			initial_horizontal_axis_position = get_global_mouse_position().x - global_position.x
		if initial_horizontal_axis_position:
			global_position.x = get_global_mouse_position().x - initial_horizontal_axis_position
		if vertical_axis_hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and initial_vertical_axis_position == 0:
			initial_vertical_axis_position = get_global_mouse_position().y - global_position.y
		if initial_vertical_axis_position:
			global_position.y = get_global_mouse_position().y - initial_vertical_axis_position
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			initial_horizontal_axis_position = 0
			initial_vertical_axis_position = 0
	if snapping:
		global_position = (round((global_position - initial_position) / Constants.CELL_SIZE) * Constants.CELL_SIZE) + initial_position
	position_changed.emit((global_position - _global_position) / Constants.CELL_SIZE)


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
	if horizontal_axis_hovered:
		horizontal_axis_color.a /= 2
	var vertical_axis_color: Color = color
	if vertical_axis_hovered:
		vertical_axis_color.a /= 2
	var length: int = 102 if outline else 100
	var width: int = 5 if outline else 1
	draw_line(Vector2(length, 0), Vector2(-length, 0), horizontal_axis_color, width, true)
	draw_line(Vector2(0, length), Vector2(0, -length), vertical_axis_color, width, true)
	draw_circle(Vector2.ZERO, width + 1.5 if outline else width + 3.0, color, true, -1, true)
	for direction in [0, 90, 180, 270]:
		var points: PackedVector2Array =[Vector2(103.5, -11.5), Vector2(115, 0), Vector2(103.5, 11.5)] if outline else [Vector2(105, -10), Vector2(115, 0), Vector2(105, 10)]
		for point in points:
			points.set(points.find(point), point.rotated(deg_to_rad(direction)))
		if direction % 180 == 0:
			draw_polyline(points, horizontal_axis_color, width, true)
		else:
			draw_polyline(points, vertical_axis_color, width, true)


func remove_gizmo(reset: bool = false) -> void:
	if is_removing:
		return
	Editor.viewport.remove_cursor_shape_override()
	is_removing = true
	state = State.DISABLED
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel()
	var do_reset_position := func(_position: Vector2):
		var position_delta = _position - global_position
		global_position += position_delta
		position_changed.emit(position_delta / Constants.CELL_SIZE)
	tween.tween_property(self, ^"gizmo_scale", 0.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, ^"modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if reset:
		tween.tween_method(do_reset_position, global_position, initial_position, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	else:
		var distance_from_start: Vector2 = initial_position - global_position
		position_changed.emit(distance_from_start / Constants.CELL_SIZE)
		confirmed.emit(-distance_from_start / Constants.CELL_SIZE)
	await tween.finished
	queue_free()


func is_enabled() -> bool:
	return state != State.DISABLED


func any_handle_hovered() -> bool:
	return horizontal_axis_hovered or vertical_axis_hovered


func _quick() -> void:
	pass
