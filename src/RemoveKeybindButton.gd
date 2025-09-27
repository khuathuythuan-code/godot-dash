extends Button

var input_event: InputEvent


func _init() -> void:
	connect("pressed", _on_button_pressed)


func _on_button_pressed() -> void:
	InputMap.action_erase_event($"../..".input_action, input_event)
	$"../..".refresh_inputs()
