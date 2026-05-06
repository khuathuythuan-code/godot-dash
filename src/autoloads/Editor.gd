extends Node

enum EditorMode {
	PLACE,
	EDIT,
	SELECTION_FILTERS,
}

var root: EditorScene
var in_editor: bool:
	get():
		return root != null
var clipboard: Variant  # Type is Selection (Rust GDExtension), declared as Variant for web compat
var snapshot := PackedScene.new()
var level_data_snapshot: Dictionary
var level_file_path: String
var level_history_version: int = 1
var shortcut_blocker: Node
var viewport: EditorViewport
var version_history: UndoRedo
var render_mode_manager: RenderMode
var temporary_playtest_level: Level
var is_picking_node: bool

# MOBILE CONTROLS
var swipe: bool = false
var delete: bool = false


func _ready() -> void:
	if OS.get_name() == "Web":
		return
	# On non-web platforms, initialize clipboard as Selection if available
	if ClassDB.class_exists("Selection"):
		clipboard = ClassDB.instantiate("Selection")


func is_text_input_focused() -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit


func clear_data() -> void:
	snapshot = PackedScene.new()
	level_data_snapshot.clear()
	level_file_path = ""
	level_history_version = 1
	version_history = UndoRedo.new()
	if ClassDB.class_exists("Selection"):
		clipboard = ClassDB.instantiate("Selection")
	else:
		clipboard = null
