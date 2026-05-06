@abstract
class_name NodeUtils

enum {
	INTERNAL = 1 << 0,
	SET_OWNER = 1 << 1,
	FORCE_READABLE_NAME = 1 << 2,
}


# Note: passing a value for the type parameter causes a crash
static func get_child_of_type(node: Node, child_type):
	for child in node.get_children():
		if is_instance_of(child, child_type):
			return child
	return null


# Note: passing a value for the type parameter causes a crash
static func get_children_of_type(node: Node, child_type, recursive: bool = false) -> Array:
	var list = []
	for child in node.get_children():
		if is_instance_of(child, child_type):
			list.append(child)
		if recursive and child.get_child_count() > 0:
			list.append_array(get_children_of_type(child, child_type, recursive))
	return list


static func set_child_owner(caller: Node, child: Node) -> void:
	var _owner: Node = caller.get_parent() if caller.get_parent().get_owner() == null else caller.get_parent().get_owner()
	child.set_owner(_owner)


static func change_owner_recursive(object: Node, object_owner: Node):
	object.owner = object_owner
	if object.get_child_count() > 0:
		object.get_children().map(change_owner_recursive.bind(object_owner))


## Return a reference to a node. If it doesn't exist, create it.
## Options:
##   - INTERNAL
##   - SET_OWNER
##   - FORCE_READABLE_NAME
static func get_node_or_add(caller: Node, path: NodePath, script, options: int = SET_OWNER) -> Node:
	var node := caller.get_node_or_null(path)
	if node == null:
		node = script.new()
		node.name = str(path)
		caller.add_child(node, options & FORCE_READABLE_NAME == FORCE_READABLE_NAME, options & INTERNAL)
		if options & SET_OWNER:
			set_child_owner.call_deferred(caller, node)
	return node


static func connect_once(_signal: Signal, callable: Callable) -> void:
	if not _signal.is_connected(callable):
		_signal.connect(callable)


static func disconnect_all(_signal: Signal) -> void:
	for connection in _signal.get_connections():
		_signal.disconnect(connection.callable)


static func free_children(caller: Node) -> void:
	caller.get_children().map(free_node)


static func free_node(node: Node) -> void:
	node.name = str(hash(node))
	node.queue_free()


static func is_valid_sprite(node: Node) -> bool:
	return node is Sprite2D or node is NinePatchSprite2D or node is ReboundOrbSprite or node is ReboundPadSprite


static func is_on_screen(node: Node, directions: Constants.Axis = Constants.Axis.BOTH, extended_border: Vector2 = Vector2.ZERO) -> bool:
	var camera_rect: Rect2 = LevelManager.current_level.camera_rect
	var camera_rect_position: Vector2 = camera_rect.position - extended_border
	var camera_rect_end: Vector2 = camera_rect.size + extended_border * 2.0
	var node_position: Vector2 = node.global_position
	match directions:
		Constants.Axis.X:
			return camera_rect_position.x < node_position.x and camera_rect_end.x > node_position.x
		Constants.Axis.Y:
			return camera_rect_position.y < node_position.y and camera_rect_end.y > node_position.y
		Constants.Axis.BOTH:
			return camera_rect_position.x < node.global_position.x and camera_rect_end.x > node_position.x and \
			camera_rect_position.y < node_position.y and camera_rect_end.y > node_position.y
	return false
