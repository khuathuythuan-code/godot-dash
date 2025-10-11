extends Node

var in_editor: bool
var editor_clipboard: Array[NodePath]
var editor_backup := PackedScene.new()
var editor_level_backup := PackedScene.new()
var shortcut_blocker: Node
var swipe: bool = false
