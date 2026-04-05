class_name InspectorTree
extends Tree

const LAYER_ICON: Texture2D = preload("res://assets/textures/icons/node_icons/layers.svg")


func refresh(selected: Array[Node2D]) -> void:
	clear()
	var layers: Array[Layer] = Editor.root.level.layers
	var root: TreeItem = create_item()
	for layer: Layer in layers:
		var layer_item: TreeItem = root.create_child()
		layer_item.set_icon(0, LAYER_ICON)
		layer_item.set_text(0, layer.name)
		for object: Node2D in layer.get_children():
			var object_item: TreeItem = layer_item.create_child()
			object_item.set_text(0, object.name)
			if object in selected:
				object_item.select(0)


func _on_edit_handler_selection_changed(selection: Selection) -> void:
	refresh(selection.to_array())


func _on_level_operations_handler_level_loaded(_level: Level) -> void:
	refresh([])


func _on_place_handler_object_deleted(_object: Node2D) -> void:
	refresh([])
