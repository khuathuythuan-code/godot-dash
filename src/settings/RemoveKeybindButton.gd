extends Button
class_name RemoveKeybindButton

var keybind_loader: KeybindLoader
var input_event: InputEvent


func _init(_keybind_loader: KeybindLoader, _input_event: InputEvent) -> void:
	keybind_loader = _keybind_loader
	input_event = _input_event


func _ready() -> void:
	icon = preload("res://assets/textures/godot_editor_icons/Remove.png")
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pressed.connect(_on_button_pressed)
	# Set `custom_minimum_size` the next frame, after the layout is solved
	# and `size` is set.
	await get_tree().process_frame
	custom_minimum_size = Vector2.ONE * get_parent().size.y


func _on_button_pressed() -> void:
	InputMap.action_erase_event(keybind_loader.input_action, input_event)
	keybind_loader.refresh_inputs()
