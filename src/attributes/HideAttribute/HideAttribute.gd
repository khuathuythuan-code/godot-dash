extends Attribute
class_name HideAttribute

func hide_safe(node: Node) -> void:
	if node is CanvasItem:
		node.hide()
	for child in node.get_children():
		hide_safe(child)

func show_safe(node: Node) -> void:
	if node is CanvasItem:
		node.show()
	for child in node.get_children():
		show_safe(child)
