class_name PathRef

var _ref: Node
var _path: NodePath


func _init(node: Node) -> void:
	_ref = node
	if not _ref.is_inside_tree():
		_ref.tree_entered.connect(func(): _path = Editor.root.level.get_path_to(node))
	else:
		_path = Editor.root.level.get_path_to(node)


func to_ref() -> Node:
	if not _ref:
		_ref = Editor.root.level.get_node_or_null(_path)
	return _ref
