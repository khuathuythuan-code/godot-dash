extends Button

var remapping: bool = false


func _init() -> void:
	connect("pressed", _on_button_pressed)


func _on_button_pressed() -> void:
	text = "Press Any Key"
	remapping = true
	$"../../../../../../../..".emit_signal("disable_escape")


func _input(event: InputEvent) -> void:
	if remapping && event is not InputEventJoypadMotion && event is not InputEventMouseMotion:
		InputMap.action_add_event($"..".input_action, event)
		$"../../../../../../../..".emit_signal("enable_escape")
		$"..".refresh_inputs()
