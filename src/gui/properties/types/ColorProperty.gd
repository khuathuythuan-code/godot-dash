@tool
extends Property

class_name ColorProperty

signal value_changed(value: Color)
signal interaction_ended(color: Color, previous: Color)

@export var default: Color
@export var button_width: float = 100.0
@warning_ignore("unused_private_class_variable")
@export_tool_button("Refresh") var _refresh = refresh

var input: ColorPickerButton
var _previous_color: Color


func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	input = NodeUtils.get_node_or_add(self, "Input", ColorPickerButton, NodeUtils.INTERNAL)
	input.color_changed.connect(func(new_value): value_changed.emit(new_value))
	input.pressed.connect(func(): _previous_color = input.get_pick_color())
	input.popup_closed.connect(func(): interaction_ended.emit(input.get_pick_color(), _previous_color))
	renamed.connect(refresh)
	refresh()
	(
		NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)
	)


func set_value(new_value: Color) -> void:
	_value = new_value
	input.set_pick_color(new_value)
	value_changed.emit(new_value)


func set_value_no_signal(new_value: Color) -> void:
	_value = new_value
	input.set_pick_color(new_value)


func get_value() -> Color:
	return input.get_pick_color()


func reset() -> void:
	set_value(default)
	interaction_ended.emit(default, input.get_pick_color())


func refresh() -> void:
	label.text = name
	input.custom_minimum_size.y = MIN_HEIGHT
	var color_picker: PopupPanel = input.get_popup()
	var color_picker_panel: Panel = color_picker.get_child(0, true)
	color_picker_panel.material = load("res://resources/SimpleBlurMaterial.tres")
	if Engine.is_editor_hint():
		reset()


func set_input_state(enabled: bool) -> void:
	input.modulate.a = 1.0 if enabled else 0.1
	input.disabled = not enabled
