class_name InspectorTree
extends Tree

func refresh() -> void:
	clear()
	var layers: Array[Layer] = Editor.root.level.layers
	var root: TreeItem = create_item()
	for layer: Layer in layers:
		var layer_item: TreeItem = create_item(root)
		layer_item.set_text(0, layer.name)
		for object: Node2D in layer.get_children():
			var object_item: TreeItem = create_item(layer_item)
			object_item.set_text(0, object.name)
