extends RichTextLabel


func _ready() -> void:
	_refresh()

func _refresh() -> void:
	text = \
			# Undo
			get_events("ui_undo") + \
			# Redo
			get_events("ui_redo") + \
			# Duplicate selected object
			get_events("editor_duplicate") + \
			# Delete selected object
			get_events("editor_delete") + \
			# Deselect object
			get_events("editor_deselect") + \
			"\n" + \
			# Open rotation gizmo
			get_events("editor_quick_rotate_free") + \
			# Rotate selected object 90°
			get_events("editor_rotate_90") + \
			# Rotate selected object -90°
			get_events("editor_rotate_-90") + \
			# Move selected object up 1 tile
			get_events("ui_up") + \
			# Move selected object left 1 tile
			get_events("ui_left") + \
			# Move selected object down 1 tile
			get_events("ui_down") + \
			# Move selected object right 1 tile
			get_events("ui_right")
	
	$"../RichTextLabel".text = "Undo
Redo
Duplicate selected object
Delete selected object
Deselect object

Open rotation gizmo
Rotate selected object 90°
Rotate selected object -90°
Move selected object up 1 tile
Move selected object left 1 tile
Move selected object down 1 tile
Move selected object right 1 tile

Hold Shift to halve movement. Ex. " + get_events("ui_up", false, "Shift+") + " moves 0.5 tiles instead of 1 tile."
	# Shift is hardcoded rn


func get_events(action: String, newline: bool = true, prefix: String = ""):
	var input_events: Array = InputMap.action_get_events(action)
	var output: String
	for input_event in input_events:
		output += (prefix + "%s / " % input_event.as_text())
	output = output.left(-3)
	if newline:
		output += "\n"
	return output
