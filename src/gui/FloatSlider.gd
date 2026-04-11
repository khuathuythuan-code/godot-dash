@tool
class_name FloatSlider
extends SpinBox

signal interaction_ended(value: float, previous: float)

enum State {
	IDLE,
	DRAGGING,
	EDITING,
}

@export var expand_to_text_length: bool
@export var tick_count: int
@export var ticks_on_borders: bool
@export var ticks_position: Slider.TickPosition

var slider: HSlider

var _previous_value: float
var _slider_initial_mouse_position: Vector2
var _state: State = State.IDLE


func _ready() -> void:
	custom_minimum_size.y = 28.0
	# Initialize the slider
	slider = HSlider.new()
	add_child.call_deferred(slider, false, INTERNAL_MODE_FRONT)
	# Reflect exports and internal nodes
	share(slider)
	update_internals.call_deferred()
	# Connect signals
	get_line_edit().editing_toggled.connect(
		func(toggled_on: bool) -> void:
			if toggled_on:
				_previous_value = value
			else:
				var emit_deferred := func(): interaction_ended.emit(value, _previous_value)
				emit_deferred.call_deferred()
				slider.mouse_filter = Control.MOUSE_FILTER_STOP
	)
	slider.drag_started.connect(
		func() -> void:
			_previous_value = value
			_slider_initial_mouse_position = get_local_mouse_position()
			_state = State.IDLE
	)
	slider.value_changed.connect(
		func(_new_value: float) -> void:
			if _state != State.IDLE:
				return
			value = _previous_value
			if get_local_mouse_position().distance_to(_slider_initial_mouse_position) > 2.0:
				_state = State.DRAGGING
				slider.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	)
	slider.drag_ended.connect(
		func(slider_value_changed: bool) -> void:
			if get_local_mouse_position().distance_to(_slider_initial_mouse_position) < 2.0:
				value = _previous_value
				_state = State.EDITING
				slider.release_focus()
				slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
				get_line_edit().edit()
			if slider_value_changed:
				interaction_ended.emit(value, _previous_value)
				_state = State.IDLE
			slider.mouse_default_cursor_shape = Control.CURSOR_ARROW
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT and _state == State.DRAGGING:
		slider.release_focus()
		interaction_ended.emit(value, _previous_value)
		_state = State.IDLE
		slider.mouse_default_cursor_shape = Control.CURSOR_ARROW


func update_internals() -> void:
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	slider.theme_type_variation = &"FloatSliderHSlider"
	slider.size = size
	slider.position = Vector2.ZERO
	slider.set_anchors_preset(PRESET_FULL_RECT)
	slider.scrollable = false
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.rounded = rounded
	slider.allow_greater = allow_greater
	slider.allow_lesser = allow_lesser
	slider.tick_count = tick_count
	slider.ticks_on_borders = ticks_on_borders
	slider.ticks_position = ticks_position
