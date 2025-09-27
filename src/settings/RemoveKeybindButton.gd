extends Button
class_name RemoveKeybindButton

var keybind_loader: KeybindLoader
var input_event: InputEvent


func _init(_keybind_loader: KeybindLoader, _input_event: InputEvent) -> void:
	keybind_loader = _keybind_loader
	input_event = _input_event


func _ready() -> void:
	text = "Remove"
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	InputMap.action_erase_event(keybind_loader.input_action, input_event)
	keybind_loader.refresh_inputs()
