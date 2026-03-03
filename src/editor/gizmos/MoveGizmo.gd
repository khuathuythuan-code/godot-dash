extends Gizmo

class_name MoveGizmo

signal position_changed(position: Vector2)

var handle_hovered: bool:
	get():
		return false
var initial_position: Vector2
var initial_mouse_position: Vector2
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
	if not is_removing:
		var _global_position = global_position
		global_position = initial_position + get_global_mouse_position() - initial_mouse_position
		if snapping:
			global_position = (round((global_position - initial_position) / Constants.CELL_SIZE) * Constants.CELL_SIZE) + initial_position
		position_changed.emit((global_position - _global_position) / Constants.CELL_SIZE)
	if get_viewport().get_camera_2d() != null:
		scale.x = 1 / get_viewport().get_camera_2d().zoom.x
		scale.y = 1 / get_viewport().get_camera_2d().zoom.y
		scale *= gizmo_scale
	else:
		scale = Vector2.ONE * gizmo_scale


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			remove_gizmo()


func _draw() -> void:
	draw_gizmo(Color.BLACK, true)
	draw_gizmo(Color.WHITE)


func draw_gizmo(color: Color, outline: bool = false) -> void:
	if outline:
		color.a /= 2
	if handle_hovered:
		color.a /= 2
	var length: int = 101 if outline else 100
	var width: int = 4 if outline else 2
	draw_line(Vector2(length, 0), Vector2(-length, 0), color, width, true)
	draw_line(Vector2(0, length), Vector2(0, -length), color, width, true)
	draw_circle(Vector2.ZERO, width + 3, color, true, -1, true)
	for direction in [0, 90, 180, 270]:
		var points: PackedVector2Array = [Vector2(100, -10), Vector2(110, 0), Vector2(100, 10)]
		for point in points:
			points.set(points.find(point), point.rotated(deg_to_rad(direction)))
		draw_polyline(points, color, width, true)


func remove_gizmo(reset: bool = false) -> void:
	if is_removing:
		return
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
	return false


func _quick() -> void:
	pass
