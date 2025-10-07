extends Node
@onready var parent: Node = get_parent()

func _feed() -> void:
	var objects: Array[Node] = parent.parent.get_children()
	objects.reverse()
	parent.call_deferred("cull", objects)
