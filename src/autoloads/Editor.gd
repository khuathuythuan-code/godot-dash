extends Node

var editor_root: EditorScene
var in_editor: bool:
	get():
		return editor_root != null
var editor_clipboard: Array[NodePath]
var editor_backup := PackedScene.new()
var editor_level_backup := PackedScene.new()
var shortcut_blocker: Node

# MOBILE CONTROLS
var swipe: bool = false
var delete: bool = false
