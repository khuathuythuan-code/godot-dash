@tool
class_name HSliderSpinBox
extends HBoxContainer

signal value_changed(value: float)
signal interaction_ended(value: float, previous: float)

@export var min_value: float
@export var max_value: float = 1.0
@export var step: float = 0.05
@export var rounded: bool
@export var allow_greater: bool
@export var allow_lesser: bool
@export var prefix: String
@export var suffix: String
@export var tick_count: int
@export var select_all_on_focus: bool
@export var editable: bool:
	set(value):
		editable = value
		if not is_node_ready():
			return
		for _range in [hslider, spinbox]:
			_range.editable = value
@export var spinbox_width: float = 90.0:
	set(value):
		spinbox_width = value
		if spinbox != null:
			spinbox.custom_minimum_size.x = value
@export var expand_to_text_length: bool

var hslider: HSlider
var spinbox: SpinBox

var value: float:
	set(value):
		value_changed.emit(value)
		set_value.call_deferred(value)
	get:
		if hslider != null:
			return hslider.value
		elif spinbox != null:
			return spinbox.value
		else:
			return 1.0 # Default value

var _spinbox_previous_value: float
var _slider_previous_value: float


func _ready() -> void:
	alignment = ALIGNMENT_CENTER
	hslider = NodeUtils.get_node_or_add(self, "HSlider", HSlider, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	hslider.custom_minimum_size.x = spinbox_width
	hslider.size_flags_vertical = Control.SIZE_FILL
	hslider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox = NodeUtils.get_node_or_add(self, "SpinBox", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	update_internals()
	spinbox.value_changed.connect(set_value)
	spinbox.get_line_edit().editing_toggled.connect(
		func(toggled_on: bool):
			if toggled_on:
				_spinbox_previous_value = spinbox.value
			else:
				interaction_ended.emit(spinbox.value, _spinbox_previous_value)
	)
	hslider.value_changed.connect(set_value)
	hslider.drag_started.connect(
		func():
			_slider_previous_value = hslider.value
			hslider.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	)
	hslider.drag_ended.connect(
		func(slider_value_changed: bool):
			if slider_value_changed:
				interaction_ended.emit(hslider.value, _slider_previous_value)
			hslider.mouse_default_cursor_shape = Control.CURSOR_ARROW
	)


func update_internals() -> void:
	for _range in [hslider, spinbox]:
		_range.min_value = min_value
		_range.max_value = max_value
		_range.step = step
		_range.rounded = rounded
		_range.allow_greater = allow_greater
		_range.allow_lesser = allow_lesser
	spinbox.prefix = prefix
	spinbox.suffix = suffix
	spinbox.select_all_on_focus = select_all_on_focus
	spinbox.get_line_edit().expand_to_text_length = expand_to_text_length
	hslider.tick_count = tick_count


func set_value(new_value: float) -> void:
	set_value_no_signal(new_value)
	value_changed.emit(value)


func set_value_no_signal(new_value: float) -> void:
	spinbox.set_value_no_signal(new_value)
	hslider.set_value_no_signal(new_value)


func get_value() -> float:
	return spinbox.value
