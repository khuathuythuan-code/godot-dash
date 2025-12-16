extends HSVWatcher

class_name PlayerHSVWatcher

func _parent_getter() -> Node2D:
	return get_parent().get_parent()
