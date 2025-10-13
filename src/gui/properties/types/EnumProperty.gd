@tool
extends Property
class_name EnumProperty

signal value_changed(value: String)

@export var default: int
@export var fields: PackedStringArray
@warning_ignore("unused_private_class_variable")
@export_tool_button("Refresh") var _refresh = refresh

var input: OptionButton

func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	input = NodeUtils.get_node_or_add(self, "Input", OptionButton, NodeUtils.INTERNAL)
	input.item_selected.connect(func(new_value): value_changed.emit(new_value))
	renamed.connect(refresh)
	refresh()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)

func set_value(new_value: int) -> void:
	_value = new_value
	input.selected = new_value
	value_changed.emit(new_value)

func set_value_no_signal(new_value: int) -> void:
	_value = new_value
	input.selected = new_value

func get_value() -> int:
	return input.selected

func reset() -> void:
	set_value(default)

func refresh() -> void:
	label.text = name
	input.clear()
	input.theme_type_variation = &"TransButton" if fields[0].begins_with("Trans ") and Config.config.enable_easter_eggs else &""
	input.custom_minimum_size.y = MIN_HEIGHT
	for field in fields:
		input.add_item(field if Config.config.enable_easter_eggs else field.trim_prefix("Trans "))
	if Engine.is_editor_hint():
		reset()

func set_input_state(enabled: bool) -> void:
	input.disabled = not enabled
