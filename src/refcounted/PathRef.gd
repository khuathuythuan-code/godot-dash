class_name PathRef

var _ref: Node
var _path: NodePath


func _init(node: Node) -> void:
	_ref = node
	if not _ref.is_inside_tree():
		_ref.tree_entered.connect(func(): _path = Editor.root.level.get_path_to(_ref))
	else:
		_path = Editor.root.level.get_path_to(node)
	_ref.renamed.connect(func(): _path = Editor.root.level.get_path_to(_ref))


func to_ref() -> Node:
	if not _ref:
		_ref = Editor.root.level.get_node_or_null(_path)
		_ref.renamed.connect(func(): _path = Editor.root.level.get_path_to(_ref))
	return _ref
