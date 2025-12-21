extends UndoRedo

class_name VersionHistory

func to_nodepath(node: Node) -> NodePath:
	return Editor.root.level.get_path_to(node)


func from_nodepath(path: NodePath) -> Node:
	return Editor.root.level.get_node(path)
