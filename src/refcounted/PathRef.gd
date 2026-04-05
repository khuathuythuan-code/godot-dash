class_name PathRef

const FREED: String = "__freed"

var _ref: Node
var _path: NodePath


func _init(node: Node) -> void:
	_ref = node
	if not _ref.is_inside_tree():
		_ref.tree_entered.connect(
			func():
				_path = Editor.root.level.get_path_to(_ref)
				NodeUtils.connect_once(_ref.get_parent().renamed, update_path)
		)
	else:
		_path = Editor.root.level.get_path_to(node)
		# HACK: renaming any parent should update the path
		NodeUtils.connect_once(_ref.get_parent().renamed, update_path)
	_ref.renamed.connect(update_path)


func to_ref() -> Node:
	if not _ref:
		_ref = Editor.root.level.get_node_or_null(_path)
		NodeUtils.connect_once(_ref.renamed, update_path)
	return _ref


func rename(new_name: String) -> void:
	if FREED in new_name or new_name.is_empty():
		return
	if _ref and not FREED in String(Editor.root.level.get_path_to(_ref)):
		_ref.name = new_name
	else:
		_path = NodePath("%s/%s" % [_path.slice(0, _path.get_name_count() - 1), new_name])
		_ref = Editor.root.level.get_node_or_null(_path)


func update_path() -> void:
	var new_path: NodePath = Editor.root.get_path_to(_ref)
	if FREED in String(new_path) or new_path.is_empty():
		return
	_path = new_path
