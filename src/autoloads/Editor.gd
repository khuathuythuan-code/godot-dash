extends Node

var editor_root: EditorScene
var in_editor: bool:
	get():
		return editor_root != null
var editor_clipboard: Array[NodePath]
var editor_backup := PackedScene.new()
var editor_level_backup: Dictionary
var shortcut_blocker: Node

# MOBILE CONTROLS
var swipe: bool = false
var delete: bool = false


func is_text_input_focused() -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit
