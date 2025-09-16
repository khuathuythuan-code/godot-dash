@tool

extends RichTextLabel


func _ready() -> void:
	_refresh()

func _refresh() -> void:
	text = \
			# Move camera (hardcoded)
			"Middle Mouse Button\n" + \
			# Zoom in (hardcoded)
			"Mouse Wheel Up / +\n" + \
			# Zoom out (hardcoded)
			"Mouse Wheel Down / -\n" + \
			# Change bottom panel tab
			get_events("editor_place_mode") + " / " + \
			get_events("editor_edit_mode") + " / " + \
			get_events("editor_selection_filters_mode")


func get_events(action: String):
	var input_events: Array = InputMap.action_get_events(action)
	var output: String
	for input_event in input_events:
		output += ("%s" % input_event.as_text())
	return output
