extends Button
class_name AddKeybindButton

var remapping: bool = false
var keybind_loader: KeybindLoader


func _init(_keybind_loader: KeybindLoader) -> void:
	keybind_loader = _keybind_loader


func _ready() -> void:
	text = "Add"
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	text = "Press Any Key"
	remapping = true
	Editor.shortcut_blocker = self
	


func _input(event: InputEvent) -> void:
	if remapping && event is not InputEventJoypadMotion && event is not InputEventMouseMotion:
		InputMap.action_add_event(keybind_loader.input_action, event)
		Editor.shortcut_blocker = null
		keybind_loader.refresh_inputs()
