extends Control
class_name ScaleGizmo

# Scale and skew
signal transform_changed(new_transform: Transform2D, new_position: Vector2)

enum ResizingState {
	DISABLED,
	ENABLED,
	FORCED,
}

const HANDLE_RADIUS: float = 6.0

var handles: Array[Handle] = [
	# Resize handles
	Handle.new(Vector2(-1.0, -1.0), Handle.Type.CORNER, 0), Handle.new(Vector2(0.0, -1.0), Handle.Type.HORIZONTAL_EDGE), Handle.new(Vector2(1.0, -1.0), Handle.Type.CORNER, 1),
	Handle.new(Vector2(-1.0, 0.0), Handle.Type.VERTICAL_EDGE), Handle.new(Vector2(1.0, 0.0), Handle.Type.VERTICAL_EDGE),
	Handle.new(Vector2(-1.0, 1.0), Handle.Type.CORNER, 3), Handle.new(Vector2(0.0, 1.0), Handle.Type.HORIZONTAL_EDGE), Handle.new(Vector2(1.0, 1.0), Handle.Type.CORNER, 2),
	# Skew handles
	Handle.new(Vector2.UP, Handle.Type.HORIZONTAL_SKEW), Handle.new(Vector2.DOWN, Handle.Type.HORIZONTAL_SKEW),
	Handle.new(Vector2.LEFT, Handle.Type.VERTICAL_SKEW), Handle.new(Vector2.RIGHT, Handle.Type.VERTICAL_SKEW),
]
var hovered_handle_idx: int
var has_hovered_handle: bool
var resizing_state: ResizingState
var handle_center_mouse_offset: Vector2
var handles_transform := Transform2D.IDENTITY.scaled(Vector2.ONE * 128.0)
var previous_mouse_position: Vector2


class Handle:
	enum Type {
		CORNER,
		VERTICAL_EDGE,
		HORIZONTAL_EDGE,
		VERTICAL_SKEW,
		HORIZONTAL_SKEW,
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
	

	func displayed_position(transform: Transform2D) -> Vector2:
		if is_skew_handle():
			var normalized_transform: Transform2D = Transform2D(transform.x.normalized(), transform.y.normalized(), Vector2.ZERO)
			var position_offset: Vector2 = position * normalized_transform * 20.0
			return position * transform + position_offset
		else:
			return position * transform
	

	func is_skew_handle() -> bool:
		return type == Type.HORIZONTAL_SKEW or type == Type.VERTICAL_SKEW


func _process(_delta: float) -> void:
	# Handle focus
	if has_hovered_handle and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and resizing_state == ResizingState.DISABLED:
		resizing_state = ResizingState.ENABLED
		handle_center_mouse_offset = handles[hovered_handle_idx].position - get_local_mouse_position()
		previous_mouse_position = get_local_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and resizing_state == ResizingState.ENABLED:
		resizing_state = ResizingState.DISABLED
	if resizing_state == ResizingState.DISABLED:
		for i: int in handles.size():
			if handles[i].displayed_position(handles_transform).distance_to(get_local_mouse_position()) < HANDLE_RADIUS:
				hovered_handle_idx = i
				has_hovered_handle = true
				break
			else:
				has_hovered_handle = false
	
	# Move handles
	if resizing_state != ResizingState.DISABLED:
		var moved_handle: Handle = handles[hovered_handle_idx]
		var mouse_position_delta: Vector2 = get_local_mouse_position() - previous_mouse_position
		# When we're not resizing around the center, we move the center of the gizmo to the mean position
		# between the opposite edge and the cursor, and resize by half the amount.
		var resize_and_move: bool = not Input.is_key_pressed(KEY_CTRL)
		var resize_and_move_multiplier: float = 0.5 if resize_and_move else 1.0
		if moved_handle.is_skew_handle():
			var skew_vector := (
					mouse_position_delta
						* moved_handle.position.rotated(PI/2) # Constrains the angle parallel to the side
						* resize_and_move_multiplier
			).rotated(PI/2)
			match moved_handle.type:
				Handle.Type.VERTICAL_SKEW:
					handles_transform.y -= skew_vector
				Handle.Type.HORIZONTAL_SKEW:
					handles_transform.x -= skew_vector
		else:
			if Input.is_key_pressed(KEY_SHIFT):
				mouse_position_delta = mouse_position_delta.project((handles_transform.x + handles_transform.y) * moved_handle.position)
			handles_transform = handles_transform.scaled_local(
					Vector2.ONE
					+ mouse_position_delta * handles_transform.affine_inverse()
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
				Handle.Type.VERTICAL_SKEW:
					position += mouse_position_delta * Vector2.DOWN * 0.5
				Handle.Type.HORIZONTAL_SKEW:
					position += mouse_position_delta * Vector2.RIGHT * 0.5
		previous_mouse_position = get_local_mouse_position()
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
	draw_polyline(corner_handles.map(func(handle: Handle): return handle.displayed_position(handles_transform)), color, 6.0 if outline else 1.0)

	for handle_idx: int in handles.size():
		var handle: Handle = handles[handle_idx]
		var handle_color: Color = color
		if has_hovered_handle and handle_idx == hovered_handle_idx:
			handle_color.a /= 2.0
		if resizing_state == ResizingState.ENABLED and handle_idx == hovered_handle_idx:
			handle_color.a /= 2.0
		if outline:
			draw_circle(handle.displayed_position(handles_transform), HANDLE_RADIUS, handle_color, false, 6.0)
		else:
			draw_circle(handle.displayed_position(handles_transform), HANDLE_RADIUS, handle_color)
	
	draw_line(Vector2.ZERO, handles_transform.x, Color.RED, 6.0)
	draw_line(Vector2.ZERO, handles_transform.y, Color.GREEN, 6.0)
