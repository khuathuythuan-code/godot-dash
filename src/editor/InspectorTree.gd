class_name InspectorTree
extends Tree

const LAYER_ICON: Texture2D = preload("res://assets/textures/icons/node_icons/layers.svg")

var selection: Selection
var selected_layers: PackedInt64Array


func _ready() -> void:
	# Init root
	create_item()


func _get_drag_data(at_position: Vector2) -> TreeItem:
	var item: TreeItem = get_item_at_position(at_position)
	return item


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var dropped_item: TreeItem = data
	var item_at_position: TreeItem = get_item_at_position(at_position)
	var is_item_layer: bool = dropped_item.get_parent() == get_root()
	var is_dropping_on_layer: bool = get_item_at_position(at_position).get_parent() == get_root()

	if not is_item_layer:
		if is_dropping_on_layer:
			drop_mode_flags = DROP_MODE_ON_ITEM
		else:
			drop_mode_flags = DROP_MODE_INBETWEEN
		return true
	elif is_dropping_on_layer:
		drop_mode_flags = DROP_MODE_INBETWEEN
		return is_cursor_closer_to_item_top(item_at_position)
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dropped_item: TreeItem = data
	var dropped_item_previous: TreeItem = dropped_item.get_prev()
	var dropped_item_next: TreeItem = dropped_item.get_next()
	var item_at_position: TreeItem = get_item_at_position(at_position)
	var is_cursor_closer_to_top = is_cursor_closer_to_item_top(item_at_position)
	# Reordering
	var is_dropping_on_layer: bool = item_at_position.get_parent() == get_root()
	var is_item_layer: bool = dropped_item.get_parent() == get_root()
	var level: Level = Editor.root.level

	var do_method: Callable
	var undo_method: Callable

	if not is_item_layer:
		var layer: Layer = level.layers[dropped_item.get_parent().get_index()]
		var path_ref: PathRef = PathRef.new(layer.get_child(dropped_item.get_index()))
		if is_dropping_on_layer:
			var new_layer: Layer = level.layers[item_at_position.get_index()]
			do_method = func():
				var reordered_object: Node2D = path_ref.to_ref()
				reordered_object.reparent(new_layer)
				new_layer.move_child(reordered_object, -1)
				dropped_item.move_after(item_at_position.get_child(-1))
				path_ref.update_path()
			undo_method = func():
				var reordered_object: Node2D = path_ref.to_ref()
				if dropped_item_previous:
					dropped_item.move_after(dropped_item_previous)
				else:
					dropped_item.move_before(dropped_item_next)
				reordered_object.reparent(layer)
				layer.move_child(reordered_object, dropped_item_previous.get_index() + 1 if dropped_item_previous else 0)
				path_ref.update_path()
		else:
			var layer_item: TreeItem = item_at_position.get_parent()
			var new_layer: Layer = level.layers[layer_item.get_index()]
			do_method = func():
				var reordered_object: Node2D = path_ref.to_ref()
				reordered_object.reparent(new_layer)
				new_layer.move_child(reordered_object, item_at_position.get_index() if is_cursor_closer_to_top else item_at_position.get_index() + 1)
				if is_cursor_closer_to_top:
					dropped_item.move_before(item_at_position)
				else:
					dropped_item.move_after(item_at_position)
				path_ref.update_path()
			undo_method = func():
				var reordered_object: Node2D = path_ref.to_ref()
				if dropped_item_previous:
					dropped_item.move_after(dropped_item_previous)
				else:
					dropped_item.move_before(dropped_item_next)
				reordered_object.reparent(layer)
				layer.move_child(reordered_object, dropped_item_previous.get_index() + 1 if dropped_item_previous else 0)
				path_ref.update_path()

	var version_history: UndoRedo = Editor.version_history
	version_history.create_action("Reordered objects")
	version_history.add_do_method(do_method)
	version_history.add_undo_method(undo_method)
	version_history.commit_action()


func is_cursor_closer_to_item_top(item_at_position: TreeItem) -> bool:
	var item_at_position_rect: Rect2 = get_item_area_rect(item_at_position)
	var is_cursor_closer_to_top: bool = get_local_mouse_position().y - item_at_position_rect.position.y < item_at_position_rect.size.y / 2.0
	return is_cursor_closer_to_top


func refresh(selected: Selection) -> void:
	selection = selected
	var root = get_root()
	var layers: Array[Layer] = Editor.root.level.layers
	for layer_idx: int in layers.size():
		var layer: Layer = layers[layer_idx]
		var layer_item: TreeItem = root.get_child(layer_idx)
		if not layer_item:
			layer_item = root.create_child()
			layer_item.set_icon(0, LAYER_ICON)
			layer_item.set_text(0, layer.name)
		if layer.get_index() in selected_layers:
			layer_item.select(0)
		for object_idx: int in layer.get_child_count():
			var object: Node2D = layer.get_child(object_idx)
			var object_item: TreeItem = layer_item.get_child(object_idx)
			if not object_item:
				object_item = layer_item.create_child()
			object_item.visible = true
			object_item.set_text(0, object.name)
			if selection.contains(object):
				object_item.select(0)
				scroll_to_item(object_item)
			else:
				object_item.deselect(0)
		if layer_item.get_child_count() > layer.get_child_count():
			for i: int in layer_item.get_child_count() - layer.get_child_count():
				var overflowing_item: TreeItem = layer_item.get_child(i + layer.get_child_count())
				overflowing_item.visible = false
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
	selection = Selection.EMPTY()
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
