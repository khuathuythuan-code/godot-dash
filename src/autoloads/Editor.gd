extends Node

var root: EditorScene
var in_editor: bool:
	get():
		return root != null
var clipboard: Array[NodePath]
var snapshot := PackedScene.new()
var level_data_snapshot: Dictionary
var level_file_name: String
var shortcut_blocker: Node
var viewport: EditorViewport

# MOBILE CONTROLS
var swipe: bool = false
var delete: bool = false


func is_text_input_focused() -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit
