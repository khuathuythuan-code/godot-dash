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
	new_selection()
	#
	#if OS.get_name() == "Web":
		#clipboard = SelectionGD.new()
		#return
	## On non-web platforms, initialize clipboard as Selection if available
	#if ClassDB.class_exists("Selection"):
		#clipboard = ClassDB.instantiate("Selection")


func is_text_input_focused() -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit


func clear_data() -> void:
	snapshot = PackedScene.new()
	level_data_snapshot.clear()
	level_file_path = ""
	level_history_version = 1
	version_history = UndoRedo.new()
	new_selection()
	#if ClassDB.class_exists("Selection"):
		#clipboard = ClassDB.instantiate("Selection")
	#else:
		#clipboard = SelectionGD.new()
		
		
# Thêm vào Editor.gd sau phần var declarations

## Tạo Selection rỗng — dùng thay cho Selection.new()
static func new_selection() -> Variant:
	if OS.has_feature("Web"):
		return SelectionGDInstance.new()
	return Selection.new()



## Tạo Selection rỗng — dùng thay cho Selection.EMPTY()
static func empty_selection() -> Variant:
	if OS.has_feature("Web"):
		return SelectionGDInstance.EMPTY()
	return Selection.EMPTY()

## Tạo Selection từ 1 object — dùng thay cho Selection.from_object()
static func selection_from_object(object: Node2D) -> Variant:
	if OS.has_feature("Web"):
		return SelectionGDInstance.from_object(object)
	return Selection.from_object(object)

## Tạo Selection từ array — dùng thay cho Selection.from_array()
static func selection_from_array(array: Array) -> Variant:
	if OS.has_feature("Web"):
		return SelectionGDInstance.from_array(array)
	return Selection.from_array(array)
