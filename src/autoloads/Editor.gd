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
		


#Selection là được tạo bằng Selection.rs nên trên web ko chạy được
#phải thay bằng Selection.gd có thể chạy các chức năng CRUD tương tự cái trên nhưng ko tốt bằng
# nên vẫn phải dùng Selection.rs cho Win
#vì editor là autoload nên cần nạp 1 giá trị bất kì khi game chạy kể cả null
# nếu ko sẽ crash,nên việc tạo Selection.gd là để cho có truyền vào thôi
# còn ko có cũng chẳng sao
# muốn chạy đc trên web thay null hoặc SelectionGDInstance vào chỗ nào có selection

static func new_selection() -> Variant:
	if OS.get_name() == "Web":
		return SelectionGDInstance.new()	
	return Selection.new()

static func empty_selection() -> Variant:
	if OS.get_name() == "Web":
		return SelectionGDInstance.EMPTY()
	return Selection.EMPTY()

static func selection_from_object(object: Node2D) -> Variant:
	if OS.get_name() == "Web":
		return SelectionGDInstance.from_object(object)
	return Selection.from_object(object)

static func selection_from_array(array: Array) -> Variant:
	if OS.get_name() == "Web":
		return SelectionGDInstance.from_array(array)
	return Selection.from_array(array)
