extends HideAttribute
class_name HideBaseAttribute

@onready var parent := get_parent().get_children()

func _ready() -> void:
	for node in parent:
		if node.get_name() == "Base":
			hide_safe(node)
			continue
		parent.remove_at(parent.find(node))


func _exit_tree() -> void:
	for node in parent:
		if node.get_name() == "Base":
			show_safe(node)
			continue
