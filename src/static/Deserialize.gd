@abstract
class_name Deserialize
## Deserialization functions for builtin types.

## Deserialize a [Transform2D] from data produced by [method Serialize.Transform2D].
static func Transform2D(data: Dictionary) -> Transform2D:
	return Transform2D(
		Deserialize.Vector2(data.x),
		Deserialize.Vector2(data.y),
		Deserialize.Vector2(data.origin),
	)


## Deserialize a [Vector2] from data produced by [method Serialize.Vector2].
static func Vector2(data: Array) -> Vector2:
	return Vector2(
		data[0],
		data[1],
	)


static func Node(path: NodePath) -> Node:
	return LevelManager.current_level.get_node_or_null(path)
