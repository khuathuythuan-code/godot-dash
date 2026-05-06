@tool
class_name FloatSliderProperty
extends Property

signal value_changed(value: float)
signal interaction_ended(value: float, previous: float)

@export var default: float
@export var min_value: float
@export var max_value: float = 100.0
@export var step: float = 0.001
@export var rounded: bool
@export var allow_lesser: bool
@export var allow_greater: bool
@export var prefix: String
@export var suffix: String
@export var slider_tick_count: int
@export var expand_to_text_length: bool
@warning_ignore("unused_private_class_variable")
@export_tool_button("Refresh") var _refresh = refresh

var input: FloatSlider


func _ready() -> void:
	label = Label.new()
	add_child(label, false, INTERNAL_MODE_FRONT)
	input = FloatSlider.new()
	add_child(input, false, INTERNAL_MODE_FRONT)
	input.value_changed.connect(value_changed.emit)
	input.interaction_ended.connect(interaction_ended.emit)
	renamed.connect(refresh)
	var line_edit: LineEdit = input.get_line_edit()
	line_edit.text_submitted.connect(submitted_release_focus)
	line_edit.editing_toggled.connect(unedit_release_focus)
	refresh()
	(
		NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)
	)


func set_value(new_value: float) -> void:
	_value = new_value
	input.set_value_no_signal(new_value)
	value_changed.emit(new_value)


func set_value_no_signal(new_value: float) -> void:
	_value = new_value
	input.set_value_no_signal(new_value)


func get_value() -> float:
	return input.get_value()


func reset() -> void:
	set_value(default)


func refresh() -> void:
	label.text = name
	input.min_value = min_value
	input.max_value = max_value
	input.step = step
	input.rounded = rounded
	input.allow_greater = allow_greater
	input.allow_lesser = allow_lesser
	input.prefix = prefix
	input.suffix = suffix
	input.tick_count = slider_tick_count
	input.select_all_on_focus = true
	input.expand_to_text_length = expand_to_text_length
	input.update_internals()
	if Engine.is_editor_hint():
		reset()


func set_input_state(enabled: bool) -> void:
	input.editable = enabled
