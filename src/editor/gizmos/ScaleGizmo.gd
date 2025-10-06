extends Gizmo
class_name ScaleGizmo

signal scale_changed(position_delta: Vector2, scale_delta: Vector2, total_scale: Vector2, rotation: float)

const HANDLE_RADIUS: float = 8.0

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
var displayed_handle_radius: float
# Deltas for the signal
var previous_position: Vector2
var previous_scale: Vector2
# Non snapped transform
var real_handles_scale: Vector2
var real_position: Vector2


class Handle:
	enum Type {
		CORNER,
		VERTICAL_EDGE,
		HORIZONTAL_EDGE,
	}

	var axis: Vector2
	var type: Type
	var corner_idx: int


	func _init(_axis: Vector2, _type: Type, _corner_idx: int = -1) -> void:
		axis = _axis
		type = _type

		if _type == Type.CORNER:
			assert(_corner_idx >= 0, "Corner Index must be defined when initializing corner handle")
			corner_idx = _corner_idx
	

	func displayed_position(scale: Vector2) -> Vector2:
		return axis * scale


func _init(_bounding_box_size: Vector2) -> void:
	bounding_box_size = _bounding_box_size * 0.5
	handles_scale = _bounding_box_size * 0.5
	real_handles_scale = handles_scale
	previous_scale = handles_scale


func _ready() -> void:
	Editor.shortcut_blocker = self
	get_viewport().gui_release_focus()
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, ^"gizmo_scale", 1.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	previous_position = position
	initial_position = position
	real_position = position
	quick_set_selected_handle.call_deferred()


func _process(_delta: float) -> void:
	# Update displayed_handle_radius
	if get_viewport().get_camera_2d():
		displayed_handle_radius = 1/get_viewport().get_camera_2d().zoom.length() * HANDLE_RADIUS
	else:
		displayed_handle_radius = HANDLE_RADIUS

	# Handle focus
	if has_hovered_handle and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == State.DISABLED:
		state = State.ENABLED
		handle_center_mouse_offset = handles[hovered_handle_idx].axis - get_local_mouse_position()
		previous_mouse_position = get_local_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == State.ENABLED:
		state = State.DISABLED
	if state == State.DISABLED:
		for i: int in handles.size():
			if handles[i].displayed_position(handles_scale).distance_to(get_local_mouse_position()) < displayed_handle_radius:
				hovered_handle_idx = i
				has_hovered_handle = true
				break
			else:
				has_hovered_handle = false
		real_handles_scale = handles_scale
		real_position = position
	
	# Move handles
	if state != State.DISABLED:
		# Modifiers
		var resizing_keep_aspect: bool = Input.is_key_pressed(KEY_SHIFT) or _quick
		var resizing_around_center: bool = Input.is_key_pressed(KEY_ALT) or _quick
		var resizing_snapped: bool = Input.is_key_pressed(KEY_CTRL)

		var moved_handle: Handle = handles[hovered_handle_idx]
		var mouse_position_delta: Vector2 = get_local_mouse_position() - previous_mouse_position
		# When we're not resizing around the center, we move the center of the gizmo to the mean position
		# between the opposite edge and the cursor, and resize by half the amount.
		var resize_and_move: bool = not resizing_around_center
		var resize_and_move_multiplier: float = 0.5 if resize_and_move else 1.0
		if resizing_keep_aspect:
			mouse_position_delta = mouse_position_delta.project(moved_handle.displayed_position(handles_scale))
		var scale_multiplier: Vector2 = (
				Vector2.ONE
				+ mouse_position_delta / real_handles_scale
					* moved_handle.axis # Constrains the angle perpendicular to the side
					* resize_and_move_multiplier
		)
		if resizing_keep_aspect and (moved_handle.axis.abs() == Vector2.RIGHT or moved_handle.axis.abs() == Vector2.DOWN):
			if scale_multiplier.x == 1.0:
				scale_multiplier.x = scale_multiplier.y
			elif scale_multiplier.y == 1.0:
				scale_multiplier.y = scale_multiplier.x
		real_handles_scale *= scale_multiplier
		# Small minimum to avoid NaN or INF-related issues
		real_handles_scale = real_handles_scale.abs().maxf(0.0000001) * real_handles_scale.sign()
		var snapped_handles_scale: Vector2 = real_handles_scale.abs().maxf(LevelManager.CELL_SIZE * 0.5).snappedf(LevelManager.CELL_SIZE * 0.5) * real_handles_scale.sign()
		if resize_and_move:
			match moved_handle.type:
				Handle.Type.CORNER:
					real_position += (mouse_position_delta * 0.5).rotated(rotation)
				Handle.Type.VERTICAL_EDGE:
					real_position += (mouse_position_delta * Vector2.RIGHT * 0.5).rotated(rotation)
				Handle.Type.HORIZONTAL_EDGE:
					real_position += (mouse_position_delta * Vector2.DOWN * 0.5).rotated(rotation)
		var snapped_position: Vector2 = initial_position + ((snapped_handles_scale - bounding_box_size) * moved_handle.axis).rotated(rotation)
		if resizing_snapped:
			handles_scale = snapped_handles_scale
			position = snapped_position if not resizing_around_center else real_position
		else:
			handles_scale = real_handles_scale
			position = real_position
		previous_mouse_position = get_local_mouse_position()
		if (handles_scale / previous_scale).is_finite():
			scale_changed.emit(
					position - previous_position,
					handles_scale / previous_scale,
					handles_scale / bounding_box_size,
					rotation,
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


func quick_set_selected_handle() -> void:
	var handle_distances_to_cursor: Array[float]
	for i: int in handles.size():
		handle_distances_to_cursor.insert(i, handles[i].displayed_position(handles_scale).distance_to(get_local_mouse_position()))
	hovered_handle_idx = handle_distances_to_cursor.find(handle_distances_to_cursor.min())


func draw_gizmo(color: Color, outline: bool = false) -> void:
	var corner_handles := handles.filter(func(handle: Handle): return handle.type == Handle.Type.CORNER)
	corner_handles.sort_custom(func(handle_a: Handle, handle_b: Handle): return handle_a.corner_idx < handle_b.corner_idx)
	corner_handles.append(corner_handles[0])
	draw_polyline(
			corner_handles.map(func(handle: Handle): return handle.displayed_position(handles_scale)),
			color,
			(displayed_handle_radius * 8.0) / HANDLE_RADIUS if outline else (displayed_handle_radius * 2.0) / HANDLE_RADIUS
	)

	for handle_idx: int in handles.size():
		var handle: Handle = handles[handle_idx]
		var handle_color: Color = color
		if has_hovered_handle and handle_idx == hovered_handle_idx:
			handle_color.a /= 2.0
		if state == State.ENABLED and handle_idx == hovered_handle_idx:
			handle_color.a /= 2.0
		if outline:
			draw_circle(handle.displayed_position(handles_scale), displayed_handle_radius, handle_color, false, displayed_handle_radius)
		else:
			draw_circle(handle.displayed_position(handles_scale), displayed_handle_radius, handle_color)
	
	if Config.config.draw_debug_overlays:
		draw_line(Vector2.ZERO, handles_scale * Vector2.RIGHT, Color.RED, 6.0)
		draw_line(Vector2.ZERO, handles_scale * Vector2.DOWN, Color.GREEN, 6.0)


func remove_gizmo(reset: bool = false) -> void:
	state = State.DISABLED
	has_hovered_handle = false
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel()
	tween.tween_property(self, ^"gizmo_scale", 0.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, ^"modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var do_reset_scale := func(weight: float, original_position: Vector2, original_scale: Vector2):
		var new_position: Vector2 = original_position.lerp(initial_position, weight)
		var new_scale: Vector2 = original_scale.lerp(bounding_box_size, weight)
		var position_delta: Vector2 = new_position - position
		var scale_delta: Vector2 = new_scale / handles_scale
		scale_changed.emit(position_delta, scale_delta, new_scale / bounding_box_size, rotation)
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
