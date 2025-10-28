@tool
extends Property
class_name NodeProperty

signal value_changed(value: NodePath)

@export var default: NodePath
@warning_ignore("unused_private_class_variable")
@export_tool_button("Refresh") var _refresh = refresh

var input: Button


func _ready() -> void:
	label = NodeUtils.get_node_or_add(self, "Label", Label, NodeUtils.INTERNAL)
	input = NodeUtils.get_node_or_add(self, "Input", Button, NodeUtils.INTERNAL)
	input.pressed.connect(_on_input_pressed)
	renamed.connect(refresh)
	refresh()
	if _value == null:
		reset()
	NodeUtils \
		.get_node_or_add(self, "PropertyReset", PropertyReset, NodeUtils.INTERNAL) \
		.set_input(input)


func set_value(new_value: NodePath) -> void:
	set_value_no_signal(new_value)
	value_changed.emit(_value)


func set_value_no_signal(new_value: NodePath) -> void:
	_value = new_value
	if _value.is_empty():
		input.text = "    Assign…    "
	else:
		input.text = new_value
		# Remove trailing dots for special nodes, e.g. LevelManager.player
		if input.text.contains(".."):
			input.text = input.text.get_file()


func get_value() -> NodePath:
	return _value


func reset() -> void:
	_value = null
	input.text = "    Assign…    "
	value_changed.emit(null)


func refresh() -> void:
	label.text = name
	if Engine.is_editor_hint():
		reset()


func set_input_state(enabled: bool) -> void:
	input.disabled = not enabled


func _on_input_pressed() -> void:
	var clipboard := Editor.editor_clipboard
	if len(clipboard) > 1:
		return
	if clipboard.is_empty() or Engine.is_editor_hint():
		reset()
	else:
		set_value(clipboard[0])
