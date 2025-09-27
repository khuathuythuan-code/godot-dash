extends VBoxContainer

@export var input_action: String


func _ready() -> void:
	refresh_inputs()


func refresh_inputs():
	var children = get_children()
	for child in children:
		child.queue_free()

	for input_event in InputMap.action_get_events(input_action):
		var container = HBoxContainer.new()
		add_child(container)
		var button = Button.new()
		button.text = input_event.as_text()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(button)
		var remove_button = Button.new()
		remove_button.text = "Remove"
		remove_button.set_script(load("res://src/RemoveKeybindButton.gd"))
		remove_button.input_event = input_event
		container.add_child(remove_button)

	var add_button = Button.new()
	add_button.text = "Add"
	add_button.set_script(load("res://src/AddKeybindButton.gd"))
	add_child(add_button)
