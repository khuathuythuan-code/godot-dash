extends HideAttribute
class_name HideDetailAttribute
@onready var parent := get_parent()

func _ready() -> void:
	var base := parent.get_node_or_null(^"Detail")
	if base:
		base.hide()

func _exit_tree() -> void:
	var base := parent.get_node_or_null(^"Detail")
	if base:
		base.show()
