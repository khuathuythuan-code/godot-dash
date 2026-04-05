class_name InspectorTree
extends Tree

const LAYER_ICON: Texture2D = preload("res://assets/textures/icons/node_icons/layers.svg")

var selection: Selection
var selected_layers: PackedInt64Array


func refresh(selected: Selection) -> void:
	selection = selected
	clear()
	var layers: Array[Layer] = Editor.root.level.layers
	var root: TreeItem = create_item()
	for layer: Layer in layers:
		var layer_item: TreeItem = root.create_child()
		layer_item.set_icon(0, LAYER_ICON)
		layer_item.set_text(0, layer.name)
		if layer.get_index() in selected_layers:
			layer_item.select(0)
		for object: Node2D in layer.get_children():
			var object_item: TreeItem = layer_item.create_child()
			object_item.set_text(0, object.name)
			if selection.contains(object):
				object_item.select(0)
				scroll_to_item(object_item)
	selected_layers.clear()


func bulk_update_selection() -> void:
	var edit_handler: EditHandler = Editor.root.edit_handler
	for i: int in selected_layers.size():
		var layer_idx: int = selected_layers[i]
		var layer: Layer = Editor.root.level.layers[layer_idx]
		var objects: Array[Node2D]
		objects.assign(layer.get_children())
		selection = selection.union(Selection.from_array(objects))
	edit_handler.select.call_deferred(selection)


func _on_edit_handler_selection_changed(new_selection: Selection) -> void:
	refresh(new_selection)


func _on_level_operations_handler_level_loaded(_level: Level) -> void:
	refresh(selection)


func _on_place_handler_object_deleted(_object: Node2D) -> void:
	refresh(selection)


func _on_multi_selected(item: TreeItem, _column: int, selected: bool) -> void:
	var is_layer: bool = item.get_parent() == get_root()
	var is_object: bool = not is_layer
	if is_object:
		var layer: Layer = Editor.root.level.layers[item.get_parent().get_index()]
		var object: Node2D = layer.get_child(item.get_index())
		if selected:
			selection = selection.union(Selection.from_object(object))
		else:
			selection = selection.difference(Selection.from_object(object))
	elif selected and item.get_index() not in selected_layers:
		selected_layers.append(item.get_index())
	bulk_update_selection.call_deferred()
