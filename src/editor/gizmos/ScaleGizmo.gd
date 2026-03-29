class_name ScaleGizmo
extends Gizmo

signal scale_changed(position: Vector2, transform: Transform2D, rotation: float, is_global_axis: bool)

const AxisConstraint = QuickGizmoValueInput.AxisConstraint

var handles: Array[Handle] = [
	# Resize handles
	Handle.new(Vector2(-1.0, -1.0), Handle.Type.CORNER, 0),
	Handle.new(Vector2(0.0, -1.0), Handle.Type.HORIZONTAL_EDGE),
	Handle.new(Vector2(1.0, -1.0), Handle.Type.CORNER, 1),
	Handle.new(Vector2(-1.0, 0.0), Handle.Type.VERTICAL_EDGE),
	Handle.new(Vector2(1.0, 0.0), Handle.Type.VERTICAL_EDGE),
	Handle.new(Vector2(-1.0, 1.0), Handle.Type.CORNER, 3),
	Handle.new(Vector2(0.0, 1.0), Handle.Type.HORIZONTAL_EDGE),
	Handle.new(Vector2(1.0, 1.0), Handle.Type.CORNER, 2),
]
var hovered_handle: Handle
var has_hovered_handle: bool
var handle_center_mouse_offset: Vector2
var transform: Transform2D
var bounding_box: Transform2D
var previous_mouse_position: Vector2
var tween: Tween
var initial_position: Vector2
var real_position: Vector2
var displayed_transform: Transform2D
var displayed_handle_radius: float


class Handle:
	enum Type {
		CORNER,
		VERTICAL_EDGE,
		HORIZONTAL_EDGE,
	}

	var axis: Vector2
	var type: Type
	var corner_idx: int
	var rotation: float


	func _init(_axis: Vector2, _type: Type, _corner_idx: int = -1) -> void:
		axis = _axis
		type = _type

		if _type == Type.CORNER:
			assert(_corner_idx >= 0, "Corner Index must be defined when initializing corner handle")
			corner_idx = _corner_idx


	func displayed_position(transform: Transform2D, global: bool = false) -> Vector2:
		# HACK: fix flipped transform rotation
		if not global:
			return axis * transform
		else:
			return (axis.rotated(rotation) * transform).rotated(-rotation)


func _init(_bounding_box: Transform2D) -> void:
	bounding_box = _bounding_box
	transform = Transform2D.IDENTITY


func _ready() -> void:
	Editor.shortcut_blocker = self
	get_viewport().gui_release_focus()
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, ^"gizmo_scale", 1.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	initial_position = position
	real_position = position
	previous_mouse_position = get_gizmo_local_mouse_position()
	displayed_transform = bounding_box * transform
	handles.map(func(handle: Handle): handle.rotation = rotation)


func _process(_delta: float) -> void:
	# Update displayed_handle_radius
	if get_viewport().get_camera_2d():
		displayed_handle_radius = 1 / get_viewport().get_camera_2d().zoom.length() * HANDLE_RADIUS
	else:
		displayed_handle_radius = HANDLE_RADIUS

	if is_zero_approx(gizmo_scale):
		return

	# Handle focus
	if has_hovered_handle and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == State.DISABLED:
		state = State.ENABLED
		handle_center_mouse_offset = hovered_handle.axis - get_local_mouse_position() / gizmo_scale
		previous_mouse_position = get_local_mouse_position() / gizmo_scale
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == State.ENABLED:
		state = State.DISABLED
	if state == State.DISABLED:
		for handle in handles:
			if handle.displayed_position(displayed_transform).distance_to(get_local_mouse_position() / gizmo_scale) < displayed_handle_radius:
				hovered_handle = handle
				has_hovered_handle = true
				break
			else:
				has_hovered_handle = false

	# Move handles
	if state != State.DISABLED:
		# Modifiers
		var resizing_keep_aspect: bool = Input.is_key_pressed(KEY_SHIFT) or is_quick
		var resizing_around_center: bool = Input.is_key_pressed(KEY_ALT) or is_quick
		var resizing_snapped: bool = Input.is_key_pressed(KEY_CTRL)

		var focused_handle: Handle = hovered_handle
		var mouse_position_delta: Vector2 = get_gizmo_local_mouse_position() - previous_mouse_position
		# When we're not resizing around the center, we move the center of the gizmo to the mean position
		# between the opposite edge and the cursor, and resize by half the amount.
		var resize_and_move: bool = not resizing_around_center
		var resize_and_move_multiplier: float = 0.5 if resize_and_move else 1.0
		if resizing_keep_aspect:
			mouse_position_delta = mouse_position_delta.project(focused_handle.displayed_position(displayed_transform))
		var scale_multiplier: Vector2 = (
			Vector2.ONE
			+ mouse_position_delta * displayed_transform.affine_inverse()
			* focused_handle.axis # Constrains the angle perpendicular to the side
			* resize_and_move_multiplier
		)
		var is_edge_handle: bool = focused_handle.type == Handle.Type.VERTICAL_EDGE or focused_handle.type == Handle.Type.HORIZONTAL_EDGE
		if resizing_keep_aspect and is_edge_handle:
			if scale_multiplier.x == 1.0:
				scale_multiplier.x = absf(scale_multiplier.y)
			elif scale_multiplier.y == 1.0:
				scale_multiplier.y = absf(scale_multiplier.x)

		if not has_quick_value():
			transform = transform.scaled(scale_multiplier)
			if is_quick:
				quick_gizmo_value_input.original_value *= scale_multiplier.x
				match quick_gizmo_value_input.get_axis_constraint():
					AxisConstraint.NONE:
						transform = Transform2D.IDENTITY.scaled(Vector2.ONE * quick_gizmo_value_input.original_value)
					AxisConstraint.GLOBAL_X, AxisConstraint.LOCAL_X:
						transform.y = transform.y.normalized()
					AxisConstraint.GLOBAL_Y, AxisConstraint.LOCAL_Y:
						transform.x = transform.x.normalized()

		if resize_and_move:
			match focused_handle.type:
				Handle.Type.CORNER:
					real_position += (mouse_position_delta * resize_and_move_multiplier).rotated(rotation)
				Handle.Type.VERTICAL_EDGE:
					real_position += (mouse_position_delta * resize_and_move_multiplier * Vector2.RIGHT).rotated(rotation)
				Handle.Type.HORIZONTAL_EDGE:
					real_position += (mouse_position_delta * resize_and_move_multiplier * Vector2.DOWN).rotated(rotation)

		var quick_and_global: bool = false if not is_quick else quick_gizmo_value_input.is_global_axis()

		if resizing_snapped:
			var snapped_transform: Transform2D = transform
			snapped_transform.x = snapped_transform.x.normalized() * maxf(snappedf(snapped_transform.x.length(), 0.5), 0.5)
			snapped_transform.y = snapped_transform.y.normalized() * maxf(snappedf(snapped_transform.y.length(), 0.5), 0.5)
			displayed_transform = bounding_box * snapped_transform
			if resizing_around_center:
				position = initial_position
			else:
				position = initial_position + (focused_handle.axis * displayed_transform - focused_handle.axis * bounding_box).rotated(rotation)
			scale_changed.emit(
				position,
				snapped_transform,
				rotation,
				quick_and_global,
			)
		else:
			displayed_transform = bounding_box * transform
			position = real_position
			scale_changed.emit(
				position,
				transform,
				rotation,
				quick_and_global,
			)

	previous_mouse_position = get_gizmo_local_mouse_position()
	set_cursor_shape(hovered_handle if has_hovered_handle else null)
	scale = Vector2.ONE * gizmo_scale
	queue_redraw()


func _draw() -> void:
	var outline_color := Color.BLACK
	outline_color.a = 0.5
	draw_gizmo(outline_color, true)
	draw_gizmo(Color.WHITE)
	if quick_gizmo_value_input:
		if quick_gizmo_value_input.is_global_axis():
			draw_set_transform(Vector2.ZERO, -rotation)
		var zoom_ratio: float = displayed_handle_radius / HANDLE_RADIUS
		match quick_gizmo_value_input.axis_constraint:
			AxisConstraint.GLOBAL_X, AxisConstraint.LOCAL_X:
				draw_line(Vector2.LEFT * 2048.0 * zoom_ratio, Vector2.RIGHT * 2048.0 * zoom_ratio, outline_color, zoom_ratio * 8.0)
				draw_line(Vector2.LEFT * 2048.0 * zoom_ratio, Vector2.RIGHT * 2048.0 * zoom_ratio, Color.RED, zoom_ratio * 2.0)
			AxisConstraint.GLOBAL_Y, AxisConstraint.LOCAL_Y:
				draw_line(Vector2.UP * 2048.0 * zoom_ratio, Vector2.DOWN * 2048.0 * zoom_ratio, outline_color, zoom_ratio * 8.0)
				draw_line(Vector2.UP * 2048.0 * zoom_ratio, Vector2.DOWN * 2048.0 * zoom_ratio, Color.GREEN, zoom_ratio * 2.0)


func _quick() -> void:
	quick_gizmo_value_input.value_changed.connect(_on_quick_scale_changed)
	quick_gizmo_value_input.axis_constraint_changed.connect(quick_set_selected_handle)
	quick_gizmo_value_input.original_value = 1.0
	quick_set_selected_handle.call_deferred(QuickGizmoValueInput.AxisConstraint.NONE)


func quick_set_selected_handle(axis_constraint: QuickGizmoValueInput.AxisConstraint) -> void:
	var quick_and_global: bool = false if not is_quick else quick_gizmo_value_input.is_global_axis()

	var considered_handles: Array[Handle]
	match axis_constraint:
		AxisConstraint.NONE:
			considered_handles.assign(handles)
		AxisConstraint.GLOBAL_X, AxisConstraint.LOCAL_X:
			considered_handles.assign(handles.filter(func(handle: Handle): return handle.type == Handle.Type.VERTICAL_EDGE))
		AxisConstraint.GLOBAL_Y, AxisConstraint.LOCAL_Y:
			considered_handles.assign(handles.filter(func(handle: Handle): return handle.type == Handle.Type.HORIZONTAL_EDGE))
	var handle_distances_to_cursor: Dictionary[Handle, float]
	for handle in considered_handles:
		handle_distances_to_cursor[handle] = handle.displayed_position(displayed_transform, quick_and_global).distance_to(get_gizmo_local_mouse_position())
	var min_distance: float = handle_distances_to_cursor.values().min()
	for handle in handle_distances_to_cursor:
		if min_distance == handle_distances_to_cursor[handle]:
			hovered_handle = handle


func draw_gizmo(color: Color, outline: bool = false) -> void:
	var quick_and_global: bool = false if not is_quick else quick_gizmo_value_input.is_global_axis()

	var corner_handles: Array = handles.filter(func(handle: Handle): return handle.type == Handle.Type.CORNER)
	corner_handles.sort_custom(func(handle_a: Handle, handle_b: Handle): return handle_a.corner_idx < handle_b.corner_idx)
	corner_handles.append(corner_handles[0])
	draw_polyline(
		corner_handles.map(func(handle: Handle): return handle.displayed_position(displayed_transform, quick_and_global)),
		color,
		(displayed_handle_radius * 8.0) / HANDLE_RADIUS if outline else (displayed_handle_radius * 2.0) / HANDLE_RADIUS,
	)

	for handle in handles:
		var handle_color: Color = color
		if handle == hovered_handle:
			if has_hovered_handle:
				handle_color.a /= 2.0
			if state == State.ENABLED:
				handle_color.a /= 2.0
		if outline:
			draw_circle(handle.displayed_position(displayed_transform, quick_and_global), displayed_handle_radius, handle_color, false, displayed_handle_radius)
		else:
			draw_circle(handle.displayed_position(displayed_transform, quick_and_global), displayed_handle_radius, handle_color)

	if Config.draw_debug_overlays:
		draw_line(Vector2.ZERO, displayed_transform.x, Color.RED, 6.0)
		draw_line(Vector2.ZERO, displayed_transform.y, Color.DARK_GREEN, 6.0)


func remove_gizmo(reset: bool = false) -> void:
	is_removing = true
	Editor.viewport.remove_cursor_shape_override()
	state = State.DISABLED
	has_hovered_handle = false
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel()
	tween.tween_property(self, ^"gizmo_scale", 0.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, ^"modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var quick_and_global: bool = is_quick and quick_gizmo_value_input.is_global_axis()
	var do_reset_scale := func(weight: float, original_position: Vector2, original_transform: Transform2D):
		var new_position: Vector2 = original_position.lerp(initial_position, weight)
		var new_transform: Transform2D = original_transform
		new_transform.x = new_transform.x.lerp(Transform2D.IDENTITY.x, weight)
		new_transform.y = new_transform.y.lerp(Transform2D.IDENTITY.y, weight)
		position = new_position
		transform = new_transform
		displayed_transform = bounding_box * transform
		scale_changed.emit(
			position,
			transform,
			rotation,
			quick_and_global,
		)
	if reset:
		tween.tween_method(do_reset_scale.bind(position, transform), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	else:
		confirmed.emit(
			position,
			transform,
			rotation,
			quick_and_global,
		)
	if quick_gizmo_value_input:
		quick_gizmo_value_input.keychord_display.text = ""
	await tween.finished
	if Editor.shortcut_blocker == self:
		Editor.shortcut_blocker = null
	queue_free()


func set_cursor_shape(active_handle: Handle) -> void:
	if not active_handle:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		Editor.viewport.remove_cursor_shape_override()
		return
	const AXES: PackedVector2Array = [
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2.UP,
		Vector2.DOWN,
		Vector2.UP + Vector2.LEFT,
		Vector2.DOWN + Vector2.LEFT,
		Vector2.UP + Vector2.RIGHT,
		Vector2.DOWN + Vector2.RIGHT,
	]
	var axis_to_dot: Dictionary[Vector2, float]
	var handle_axis: Vector2 = active_handle.axis.rotated(rotation).normalized()
	for axis: Vector2 in AXES:
		axis_to_dot[axis] = absf(axis.normalized().dot(handle_axis) - 1.0)
	var closest_axis_dot: float = axis_to_dot.values().min()
	var closest_axis: Vector2 = axis_to_dot.find_key(closest_axis_dot)
	match closest_axis:
		Vector2.LEFT, Vector2.RIGHT:
			Editor.viewport.override_cursor_shape(Control.CURSOR_HSIZE)
		Vector2.UP, Vector2.DOWN:
			Editor.viewport.override_cursor_shape(Control.CURSOR_VSIZE)
		(Vector2.UP + Vector2.LEFT), (Vector2.DOWN + Vector2.RIGHT):
			Editor.viewport.override_cursor_shape(Control.CURSOR_FDIAGSIZE)
		(Vector2.UP + Vector2.RIGHT), (Vector2.DOWN + Vector2.LEFT):
			Editor.viewport.override_cursor_shape(Control.CURSOR_BDIAGSIZE)


func is_enabled() -> bool:
	return state != State.DISABLED


func any_handle_hovered() -> bool:
	return has_hovered_handle


func _on_quick_scale_changed(quick_scale: float) -> void:
	match quick_gizmo_value_input.axis_constraint:
		AxisConstraint.NONE:
			transform = Transform2D.IDENTITY.scaled(Vector2.ONE * quick_scale)
		AxisConstraint.GLOBAL_X, AxisConstraint.LOCAL_X:
			transform = Transform2D.IDENTITY.scaled(Vector2(quick_scale, 1.0))
		AxisConstraint.GLOBAL_Y, AxisConstraint.LOCAL_Y:
			transform = Transform2D.IDENTITY.scaled(Vector2(1.0, quick_scale))
	if quick_scale == quick_gizmo_value_input.original_value:
		transform = Transform2D.IDENTITY.scaled(Vector2.ONE * quick_scale)
