extends HideAttribute
class_name HideDetailAttribute
@onready var parent := get_parent().get_children()

func _ready() -> void:
	for node in parent:
		if node and node.get_name() == "Detail":
			hide_safe(node)
			continue
		parent.remove_at(parent.find(node))


func _exit_tree() -> void:
	for node in parent:
		if node and node.get_name() == "Detail":
			show_safe(node)
			continue
