@tool
extends Property

class_name NodeProperty

signal value_changed(value: NodePath)
signal interaction_ended(value: NodePath, previous: NodePath)

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
	var previous: NodePath = _value
	set_value_no_signal(new_value)
	value_changed.emit(_value)
	interaction_ended.emit(_value, previous)


func set_value_no_signal(new_value: NodePath) -> void:
	if new_value.is_empty():
		input.text = "    Assign…    "
	else:
		input.text = new_value
		# Remove trailing dots for special nodes, e.g. LevelManager.player
		if input.text.contains(".."):
			input.text = input.text.get_file()
	_value = new_value


func get_value() -> NodePath:
	return _value


func reset() -> void:
	_value = ^""
	input.text = "    Assign…    "
	value_changed.emit(^"")


func refresh() -> void:
	label.text = name
	if Engine.is_editor_hint():
		reset()


func set_input_state(enabled: bool) -> void:
	input.disabled = not enabled


func _on_input_pressed() -> void:
	var clipboard := Editor.clipboard
	if clipboard.size() > 1:
		Toasts.warning("Copy a single object to assign it")
		return
	if clipboard.is_empty() or Engine.is_editor_hint():
		Toasts.warning("Copy a single object to assign it")
		reset()
	else:
		set_value(Editor.root.level.get_path_to(clipboard.first()))
