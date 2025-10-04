extends Gizmo
class_name ScaleGizmo

signal scale_changed(position_delta: Vector2, scale_delta: Vector2)

const HANDLE_RADIUS: float = 6.0

var handles: Array[Handle] = [
	# Resize handles
	Handle.new(Vector2(-1.0, -1.0), Handle.Type.CORNER, 0), Handle.new(Vector2(0.0, -1.0), Handle.Type.HORIZONTAL_EDGE), Handle.new(Vector2(1.0, -1.0), Handle.Type.CORNER, 1),
	Handle.new(Vector2(-1.0, 0.0), Handle.Type.VERTICAL_EDGE), Handle.new(Vector2(1.0, 0.0), Handle.Type.VERTICAL_EDGE),
	Handle.new(Vector2(-1.0, 1.0), Handle.Type.CORNER, 3), Handle.new(Vector2(0.0, 1.0), Handle.Type.HORIZONTAL_EDGE), Handle.new(Vector2(1.0, 1.0), Handle.Type.CORNER, 2),
]
var hovered_handle_idx: int
var has_hovered_handle: bool
var handle_center_mouse_offset: Vector2
var handles_scale: Vector2
var previous_mouse_position: Vector2
var tween: Tween
var bounding_box_size: Vector2
var initial_position: Vector2
# Deltas for the signal
var previous_position: Vector2
var previous_scale: Vector2


class Handle:
	enum Type {
		CORNER,
		VERTICAL_EDGE,
		HORIZONTAL_EDGE,
	}

	var position: Vector2
	var type: Type
	var corner_idx: int


	func _init(_position: Vector2, _type: Type, _corner_idx: int = -1) -> void:
		position = _position
		type = _type

		if _type == Type.CORNER:
			assert(_corner_idx >= 0, "Corner Index must be defined when initializing corner handle")
			corner_idx = _corner_idx
	

	func displayed_position(scale: Vector2) -> Vector2:
		return position * scale


func _init(_bounding_box_size: Vector2) -> void:
	bounding_box_size = _bounding_box_size
	handles_scale = _bounding_box_size * 0.5
	previous_scale = handles_scale


func _ready() -> void:
	Editor.shortcut_blocker = self
	get_viewport().gui_release_focus()
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, ^"gizmo_scale", 1.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	(func(): 
		previous_position = position
		initial_position = position
	).call_deferred()


func _process(_delta: float) -> void:
	# Handle focus
	if has_hovered_handle and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == State.DISABLED:
		state = State.ENABLED
		handle_center_mouse_offset = handles[hovered_handle_idx].position - get_local_mouse_position()
		previous_mouse_position = get_local_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == State.ENABLED:
		state = State.DISABLED
	if state == State.DISABLED:
		for i: int in handles.size():
			if handles[i].displayed_position(handles_scale).distance_to(get_local_mouse_position()) < HANDLE_RADIUS:
				hovered_handle_idx = i
				has_hovered_handle = true
				break
			else:
				has_hovered_handle = false
	
	# Move handles
	if state != State.DISABLED:
		var moved_handle: Handle = handles[hovered_handle_idx]
		var mouse_position_delta: Vector2 = get_local_mouse_position() - previous_mouse_position
		# When we're not resizing around the center, we move the center of the gizmo to the mean position
		# between the opposite edge and the cursor, and resize by half the amount.
		var resize_and_move: bool = not Input.is_key_pressed(KEY_CTRL)
		var resize_and_move_multiplier: float = 0.5 if resize_and_move else 1.0
		if Input.is_key_pressed(KEY_SHIFT):
			mouse_position_delta = mouse_position_delta.project(moved_handle.displayed_position(handles_scale))
		handles_scale *= (
				Vector2.ONE
				+ mouse_position_delta / handles_scale
					* moved_handle.position # Constrains the angle perpendicular to the side
					* resize_and_move_multiplier
		)
		if resize_and_move:
			match moved_handle.type:
				Handle.Type.CORNER:
					position += mouse_position_delta * 0.5
				Handle.Type.VERTICAL_EDGE:
					position += mouse_position_delta * Vector2.RIGHT * 0.5
				Handle.Type.HORIZONTAL_EDGE:
					position += mouse_position_delta * Vector2.DOWN * 0.5
		previous_mouse_position = get_local_mouse_position()
		scale_changed.emit(
				position - previous_position,
				handles_scale / previous_scale,
		)
		previous_position = position
		previous_scale = handles_scale
	
	scale = Vector2.ONE * gizmo_scale
	queue_redraw()


func _draw() -> void:
	var outline_color := Color.BLACK
	outline_color.a = 0.5
	draw_gizmo(outline_color, true)
	draw_gizmo(Color.WHITE)


func draw_gizmo(color: Color, outline: bool = false) -> void:
	var corner_handles := handles.filter(func(handle: Handle): return handle.type == Handle.Type.CORNER)
	corner_handles.sort_custom(func(handle_a: Handle, handle_b: Handle): return handle_a.corner_idx < handle_b.corner_idx)
	corner_handles.append(corner_handles[0])
	draw_polyline(corner_handles.map(func(handle: Handle): return handle.displayed_position(handles_scale)), color, 6.0 if outline else 1.0)

	for handle_idx: int in handles.size():
		var handle: Handle = handles[handle_idx]
		var handle_color: Color = color
		if has_hovered_handle and handle_idx == hovered_handle_idx:
			handle_color.a /= 2.0
		if state == State.ENABLED and handle_idx == hovered_handle_idx:
			handle_color.a /= 2.0
		if outline:
			draw_circle(handle.displayed_position(handles_scale), HANDLE_RADIUS, handle_color, false, 6.0)
		else:
			draw_circle(handle.displayed_position(handles_scale), HANDLE_RADIUS, handle_color)
	
	if Config.config.draw_debug_overlays:
		draw_line(Vector2.ZERO, handles_scale * Vector2.RIGHT, Color.RED, 6.0)
		draw_line(Vector2.ZERO, handles_scale * Vector2.DOWN, Color.GREEN, 6.0)


func remove_gizmo(reset: bool = false) -> void:
	state = State.DISABLED
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel()
	tween.tween_property(self, ^"gizmo_scale", 0.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, ^"modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var do_reset_scale := func(weight: float, original_position: Vector2, original_scale: Vector2):
		var new_position: Vector2 = original_position.lerp(initial_position, weight)
		var new_scale: Vector2 = original_scale.lerp(bounding_box_size * 0.5, weight)
		var position_delta: Vector2 = new_position - position
		var scale_delta: Vector2 = new_scale / handles_scale
		print(position_delta, scale_delta)
		scale_changed.emit(position_delta, scale_delta)
		position = new_position
		handles_scale = new_scale
	if reset:
		tween.tween_method(do_reset_scale.bind(position, handles_scale), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if quick_gizmo_value_input:
		quick_gizmo_value_input.keychord_display.text = ""
	await tween.finished
	if Editor.shortcut_blocker == self:
		Editor.shortcut_blocker = null
	queue_free()


func is_enabled() -> bool:
	return state != State.DISABLED


func any_handle_hovered() -> bool:
	return has_hovered_handle
