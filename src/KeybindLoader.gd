extends VBoxContainer

@export var input_action: String


func _ready() -> void:
	refresh_inputs()

func refresh_inputs():
	for input_event in InputMap.action_get_events(input_action):
		var button = Button.new()
		button.text = input_event.as_text()
		add_child(button)
