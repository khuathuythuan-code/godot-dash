class_name InspectorTree
extends Tree

const LAYER_ICON: Texture2D = preload("res://assets/textures/icons/node_icons/layers.svg")
const VISIBLE_ICON: Texture2D = preload("res://assets/textures/icons/godot/GuiVisibilityVisible.svg")
const HIDDEN_ICON: Texture2D = preload("res://assets/textures/icons/godot/GuiVisibilityHidden.svg")

@export var search_box: LineEdit

var selection: Selection
var hidden_items: Array[TreeItem]
var flat_item_list: Array[TreeItem]
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
	if not item_at_position:
		item_at_position = get_last_tree_item()
	var is_item_layer: bool = dropped_item.get_parent() == get_root()
	var is_dropping_on_layer: bool = item_at_position.get_parent() == get_root()

	if not is_item_layer:
		if is_dropping_on_layer:
			drop_mode_flags = DROP_MODE_ON_ITEM
		else:
			drop_mode_flags = DROP_MODE_INBETWEEN
		return true
	elif is_dropping_on_layer and get_drop_section_at_position(at_position) == -1:
		drop_mode_flags = DROP_MODE_INBETWEEN
		return true
	else:
		drop_mode_flags = DROP_MODE_DISABLED
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dropped_item: TreeItem = data
	var dropped_item_previous: TreeItem = dropped_item.get_prev()
	var dropped_item_next: TreeItem = dropped_item.get_next()
	var item_at_position: TreeItem = get_item_at_position(at_position)
	if not item_at_position:
		item_at_position = get_last_tree_item()
	var is_cursor_closer_to_top = get_drop_section_at_position(at_position) == -1
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


func get_last_tree_item() -> TreeItem:
	var last_tree_item: TreeItem = get_root().get_child(-1)
	if not last_tree_item:
		return null
	while last_tree_item.get_child_count() > 0:
		last_tree_item = last_tree_item.get_child(-1)
	return last_tree_item


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
			layer_item.add_button(0, VISIBLE_ICON)
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
		hidden_items.clear()
		if layer_item.get_child_count() > layer.get_child_count():
			for i: int in layer_item.get_child_count() - layer.get_child_count():
				var overflowing_item: TreeItem = layer_item.get_child(i + layer.get_child_count())
				overflowing_item.visible = false
				hidden_items.append(overflowing_item)
		# layer_item.set_button(0, "%s %s" % [layer.get_child_count(), StringUtils.pluralize("object", layer.get_child_count())])
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


func filter_items(match_expr: String) -> void:
	if match_expr.is_empty():
		for item: TreeItem in flat_item_list:
			item.visible = true
		return
	var valid_items: Array[TreeItem]
	for item: TreeItem in flat_item_list:
		if is_zero_approx(item.get_text(0).similarity(match_expr)):
			item.visible = false
			continue
		item.uncollapse_tree()
		if item not in valid_items:
			valid_items.append(item)
		# Parents need to be visible for the item to be visible too.
		for item_parent: TreeItem in get_item_parents(item):
			if item_parent not in valid_items:
				valid_items.append(item_parent)
	for valid_item: TreeItem in valid_items:
		valid_item.visible = true


func get_flat_visible_item_list() -> Array[TreeItem]:
	var new_flat_item_list: Array[TreeItem]
	_get_flat_item_list_inner(get_root(), new_flat_item_list)
	return new_flat_item_list


func get_item_parents(item: TreeItem) -> Array[TreeItem]:
	var parents: Array[TreeItem]
	var traversed_item: TreeItem = item
	while traversed_item.get_parent() != get_root():
		traversed_item = traversed_item.get_parent()
		parents.append(traversed_item)
	return parents


func _get_flat_item_list_inner(item: TreeItem, new_flat_item_list: Array[TreeItem], depth: int = 0) -> void:
	const MAX_RECURSION_DEPTH: int = 6
	if depth >= MAX_RECURSION_DEPTH or item.get_child_count() == 0:
		return
	for child_item: TreeItem in item.get_children():
		if child_item in hidden_items:
			continue
		new_flat_item_list.append(child_item)
		_get_flat_item_list_inner(child_item, new_flat_item_list, depth + 1)


func _on_edit_handler_selection_changed(new_selection: Selection) -> void:
	refresh(new_selection)


func _on_level_operations_handler_level_loaded(_level: Level) -> void:
	selection = Selection.EMPTY()
	refresh(selection)


func _on_place_handler_object_deleted(_object: Node2D) -> void:
	refresh(selection)


func _on_multi_selected(item: TreeItem, _column: int, selected: bool) -> void:
	var is_item_layer: bool = item.get_parent() == get_root()
	var is_object: bool = not is_item_layer
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


func _on_button_clicked(item: TreeItem, column: int, id: int, _mouse_button_index: int) -> void:
	var is_item_layer: bool = item.get_parent() == get_root()
	if not is_item_layer:
		return
	var button_texture: Texture2D = item.get_button(column, id)
	var is_item_button_toggled: bool = button_texture == HIDDEN_ICON
	var layer_idx: int = item.get_index()
	var layer: Layer = Editor.root.level.layers[layer_idx]
	layer.hidden_in_editor = not is_item_button_toggled
	item.set_button(column, id, VISIBLE_ICON if is_item_button_toggled else HIDDEN_ICON)


func _on_search_box_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		flat_item_list = get_flat_visible_item_list()


func _on_search_box_text_changed(new_text: String) -> void:
	filter_items(new_text)


func _on_search_box_text_submitted(layer_name: String) -> void:
	search_box.clear()
	Editor.root.level.create_layer(layer_name)
	refresh(selection)


func _on_confirm_pressed() -> void:
	var layer_name: String = search_box.text
	search_box.clear()
	Editor.root.level.create_layer(layer_name)
	refresh(selection)


func _on_inspector_manager_renamed_object(object: Node2D, new_name: String) -> void:
	var layer: Layer = object.get_parent()
	var layer_item: TreeItem = get_root().get_child(layer.get_index())
	var object_item: TreeItem = layer_item.get_child(object.get_index())
	object_item.set_text(0, new_name)
