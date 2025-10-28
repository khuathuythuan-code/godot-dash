@tool
extends Property
class_name MultilineStringProperty

signal value_changed(value: String)

@export var default: String
@export var placeholder: String
@warning_ignore("unused_private_class_variable")
@export_tool_button("Refresh") var _refresh = refresh

var input: TextEdit


func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	input = NodeUtils.get_node_or_add(self, "Input", TextEdit, NodeUtils.INTERNAL)
	input.text_changed.connect(func(new_value): value_changed.emit(new_value))
	renamed.connect(refresh)
	refresh()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)


func set_value(new_value: String) -> void:
	_value = new_value
	input.set_text(new_value)
	value_changed.emit(new_value)


func set_value_no_signal(new_value: String) -> void:
	_value = new_value
	input.set_text(new_value)


func get_value() -> String:
	return input.get_text()


func reset() -> void:
	set_value(default)


func refresh() -> void:
	label.text = name
	input.focus_mode = Control.FOCUS_CLICK
	input.placeholder_text = placeholder
	input.scroll_smooth = true
	input.scroll_fit_content_height = true
	if Engine.is_editor_hint():
		reset()


func set_input_state(enabled: bool) -> void:
	input.editable = enabled
