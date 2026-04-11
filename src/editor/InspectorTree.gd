class_name InspectorTree
extends Tree

const LAYER_ICON: Texture2D = preload("res://assets/textures/icons/lucide/layers.svg")
const VISIBLE_ICON: Texture2D = preload("res://assets/textures/icons/godot/GuiVisibilityVisible.svg")
const HIDDEN_ICON: Texture2D = preload("res://assets/textures/icons/godot/GuiVisibilityHidden.svg")
const LOCK_ICON: Texture2D = preload("res://assets/textures/icons/godot/Lock.svg")
const UNLOCK_ICON: Texture2D = preload("res://assets/textures/icons/godot/Unlock.svg")

enum LayerIcon {
	VISIBILITY,
	LOCK,
}

@export var search_box: LineEdit

var selection: Selection
var hidden_items: Array[TreeItem]
var flat_item_list: Array[TreeItem]


func _ready() -> void:
	# Init root
	create_item()


func _get_drag_data(at_position: Vector2) -> TreeItem:
	var item: TreeItem = get_item_at_position(at_position)
	return item


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var dropped_item: TreeItem = data
	var item_at_position: TreeItem = get_item_at_position(at_position)
	var is_dropping_at_tree_end: bool = false
	if not item_at_position:
		item_at_position = get_last_tree_item()
		is_dropping_at_tree_end = true
	var is_item_layer: bool = dropped_item.get_parent() == get_root()
	var is_dropping_on_layer: bool = item_at_position.get_parent() == get_root()

	if not is_item_layer:
		if is_dropping_on_layer:
			drop_mode_flags = DROP_MODE_ON_ITEM
		else:
			drop_mode_flags = DROP_MODE_INBETWEEN
		return true
	elif is_dropping_at_tree_end or is_dropping_on_layer and get_drop_section_at_position(at_position) == -1:
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
	var is_dropping_at_tree_end: bool = false
	if not item_at_position:
		item_at_position = get_last_tree_item()
		is_dropping_at_tree_end = true
	var is_cursor_closer_to_top = get_drop_section_at_position(at_position) == -1
	# Reordering
	var is_dropping_on_layer: bool = item_at_position.get_parent() == get_root()
	var is_item_layer: bool = dropped_item.get_parent() == get_root()
	var level: Level = Editor.root.level

	var do_method: Callable
	var undo_method: Callable

	if not is_item_layer:
		var layer: Layer = level.layers[dropped_item.get_parent().get_index()]
		var reordered_object: Node2D = layer.get_child(dropped_item.get_index())

		if is_dropping_on_layer:
			var new_layer: Layer = level.layers[item_at_position.get_index()]
			do_method = func():
				reordered_object.reparent(new_layer)
				new_layer.move_child(reordered_object, -1)
				if item_at_position.get_child_count() > 0:
					dropped_item.move_after(item_at_position.get_child(-1))
				else:
					dropped_item.get_parent().remove_child(dropped_item)
					item_at_position.add_child(dropped_item)
			undo_method = func():
				if dropped_item_previous:
					dropped_item.move_after(dropped_item_previous)
				else:
					dropped_item.move_before(dropped_item_next)
				reordered_object.reparent(layer)
				layer.move_child(reordered_object, dropped_item_previous.get_index() + 1 if dropped_item_previous else 0)
		else:
			var layer_item: TreeItem = item_at_position.get_parent()
			var new_layer: Layer = level.layers[layer_item.get_index()]
			do_method = func():
				reordered_object.reparent(new_layer)
				new_layer.move_child(reordered_object, item_at_position.get_index() if is_cursor_closer_to_top else item_at_position.get_index() + 1)
				if is_cursor_closer_to_top:
					dropped_item.move_before(item_at_position)
				else:
					dropped_item.move_after(item_at_position)
			undo_method = func():
				if dropped_item_previous:
					dropped_item.move_after(dropped_item_previous)
				else:
					dropped_item.move_before(dropped_item_next)
				reordered_object.reparent(layer)
				layer.move_child(reordered_object, dropped_item_previous.get_index() + 1 if dropped_item_previous else 0)
	else:
		var layer: Layer = level.layers[dropped_item.get_index()]
		var layer_name: String = layer.name
		var new_layer_idx: int = item_at_position.get_index() if not is_dropping_at_tree_end else -1
		do_method = func():
			var layer_item_at_position: TreeItem = item_at_position if is_dropping_on_layer else item_at_position.get_parent()
			level.move_layer(layer_name, new_layer_idx)
			if is_cursor_closer_to_top:
				dropped_item.move_before(layer_item_at_position)
			else:
				dropped_item.move_after(layer_item_at_position)
		undo_method = func():
			if dropped_item_previous:
				dropped_item.move_after(dropped_item_previous)
			else:
				dropped_item.move_before(dropped_item_next)
			level.move_layer(layer_name, dropped_item_previous.get_index() + 1 if dropped_item_previous else 0)

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


func refresh(selected: Selection = selection) -> void:
	selection = selected
	var root: TreeItem = get_root()
	var level: Level = Editor.root.level
	var layers: Array[Layer] = level.layers
	for layer_idx: int in layers.size():
		var layer: Layer = layers[layer_idx]
		var layer_item: TreeItem
		if layer_idx >= root.get_child_count():
			layer_item = root.create_child()
			layer_item.set_icon(0, LAYER_ICON)
			layer_item.set_text(0, layer.name)
			layer_item.add_button(0, VISIBLE_ICON)
			layer_item.add_button(0, UNLOCK_ICON)
			layer_item.set_editable(0, true)
		else:
			layer_item = root.get_child(layer_idx)
		layer_item.visible = true
		for object_idx: int in layer.get_child_count():
			var object: Node2D = layer.get_child(object_idx)
			var object_item: TreeItem = layer_item.get_child(object_idx) if object_idx < layer_item.get_child_count() else layer_item.create_child()
			object_item.visible = true
			object_item.set_text(0, object.name)
			object_item.set_editable(0, true)
			object_item.set_icon(0, ObjectThumbnail.generate(object, 16))
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
	if root.get_child_count() > level.get_child_count():
		for i: int in root.get_child_count() - level.get_child_count():
			var overflowing_item: TreeItem = root.get_child(i + level.get_child_count())
			overflowing_item.visible = false
			hidden_items.append(overflowing_item)

	update_active_layer(false)

	var selected_item: TreeItem = get_next_selected(null)
	if not selected_item:
		return
	# Prioritize objects over layers
	if selected_item.get_parent() == root and get_next_selected(selected_item):
		selected_item = get_next_selected(selected_item)
	selected_item.get_parent().set_collapsed(false)
	await get_tree().process_frame # Wait for rect to be updated


func update_active_layer(is_changing_single_layer_selection: bool) -> void:
	var root: TreeItem = get_root()
	var level: Level = Editor.root.level
	var first_item_in_selection: TreeItem = get_next_selected(null)
	var selection_is_single_layer: bool = first_item_in_selection and first_item_in_selection.get_parent() == root
	if not selection_is_single_layer:
		return
	var new_active_layer_idx: int = first_item_in_selection.get_index()
	if level.active_layer_idx == new_active_layer_idx:
		return
	if is_changing_single_layer_selection:
		Editor.version_history.create_action("Set active layer to %s" % root.get_child(new_active_layer_idx).get_text(0))
	else:
		Editor.version_history.create_action(Editor.version_history.get_current_action_name(), UndoRedo.MERGE_ALL)
	Editor.version_history.add_do_method(set_active_layer.bind(level.active_layer_idx, new_active_layer_idx))
	Editor.version_history.add_do_method(_set_layer_item_selected_silent.bind(level.active_layer_idx, new_active_layer_idx, is_changing_single_layer_selection, true))
	Editor.version_history.add_undo_method(set_active_layer.bind(new_active_layer_idx, level.active_layer_idx))
	Editor.version_history.add_undo_method(_set_layer_item_selected_silent.bind(level.active_layer_idx, new_active_layer_idx, is_changing_single_layer_selection, false))
	Editor.version_history.commit_action()


func set_active_layer(previous_layer_idx: int, new_layer_idx: int) -> void:
	var root: TreeItem = get_root()
	var level: Level = Editor.root.level
	root.get_child(previous_layer_idx).clear_custom_bg_color(0)
	level.active_layer_idx = new_layer_idx
	root.get_child(new_layer_idx).set_custom_bg_color(0, Color.WHITE, true)


func handle_item_rename(item: TreeItem) -> void:
	var is_item_layer: bool = item.get_parent() == get_root()
	var new_name: String = item.get_text(0)
	if is_item_layer:
		_update_layer_name(item, new_name)
	else:
		Editor.root.inspector_manager.update_object_name(new_name)


func set_items_editable(editable: bool) -> void:
	for item: TreeItem in get_flat_visible_item_list():
		item.set_editable(0, editable)


func get_selected_items() -> Array[TreeItem]:
	var item: TreeItem = null
	var selected_items: Array[TreeItem]
	while get_next_selected(item):
		selected_items.append(get_next_selected(item))
		item = get_next_selected(item)
	return selected_items


func set_selected_items(selected_items: Array[TreeItem]) -> void:
	for item: TreeItem in get_flat_visible_item_list():
		if item in selected_items:
			item.select(0)
		else:
			item.deselect(0)


func bulk_update_selection(is_caller_selected: bool) -> void:
	var edit_handler: EditHandler = Editor.root.edit_handler
	if selection.is_identical(edit_handler.selection) and is_caller_selected:
		update_active_layer(true)
		return
	edit_handler.select(selection)


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


func _set_layer_item_selected_silent(
		previous_layer_idx: int,
		new_layer_idx: int,
		is_changing_single_layer_selection: bool,
		selected: bool,
) -> void:
	var root: TreeItem = get_root()
	var layer_item: TreeItem = root.get_child(new_layer_idx)
	layer_item.set_metadata(0, true)
	if selected:
		layer_item.select(0)
	else:
		layer_item.deselect(0)
	if is_changing_single_layer_selection:
		var previous_layer_item: TreeItem = root.get_child(previous_layer_idx)
		previous_layer_item.set_metadata(0, true)
		if selected:
			previous_layer_item.deselect(0)
		else:
			previous_layer_item.select(0)


func _update_layer_name(item: TreeItem, new_name: String) -> void:
	var layer: Layer = Editor.root.level.layers[item.get_index()]
	var previous_name: String = layer.name
	var sanitized_new_name: String = new_name.validate_node_name()
	Editor.version_history.create_action("Renamed layer %s to %s" % [previous_name, sanitized_new_name])
	Editor.version_history.add_do_method(
		func():
			layer.name = sanitized_new_name
			item.set_text(0, sanitized_new_name)
	)
	Editor.version_history.add_undo_method(
		func():
			layer.name = previous_name
			item.set_text(0, previous_name)
	)
	Editor.version_history.commit_action()


func _on_edit_handler_selection_changed(new_selection: Selection) -> void:
	refresh(new_selection)


func _on_level_operations_handler_level_loaded(_level: Level) -> void:
	selection = Selection.EMPTY()
	clear()
	create_item()
	refresh()
	set_active_layer(0, 0)


func _on_place_handler_object_deleted(_object: Node2D) -> void:
	refresh()


func _on_multi_selected(item: TreeItem, _column: int, selected: bool) -> void:
	if Editor.is_picking_node:
		return
	if item.get_metadata(0):
		item.set_metadata(0, false)
		return
	var is_item_layer: bool = item.get_parent() == get_root()
	var is_object: bool = not is_item_layer
	if is_object:
		var layer: Layer = Editor.root.level.layers[item.get_parent().get_index()]
		var object: Node2D = layer.get_child(item.get_index())
		if selected:
			selection = selection.union(Selection.from_object(object))
		else:
			selection = selection.difference(Selection.from_object(object))
	bulk_update_selection.call_deferred(selected)


func _on_button_clicked(item: TreeItem, column: int, id: int, _mouse_button_index: int) -> void:
	var is_item_layer: bool = item.get_parent() == get_root()
	if not is_item_layer:
		return
	var button_texture: Texture2D = item.get_button(column, id)
	var layer_idx: int = item.get_index()
	var layer: Layer = Editor.root.level.layers[layer_idx]
	var on_state_texture: Texture2D
	var off_state_texture: Texture2D
	match id as LayerIcon:
		LayerIcon.VISIBILITY:
			on_state_texture = HIDDEN_ICON
			off_state_texture = VISIBLE_ICON
		LayerIcon.LOCK:
			on_state_texture = LOCK_ICON
			off_state_texture = UNLOCK_ICON
	var is_item_button_toggled: bool = button_texture == on_state_texture
	match id as LayerIcon:
		LayerIcon.VISIBILITY:
			layer.hidden_in_editor = not is_item_button_toggled
		LayerIcon.LOCK:
			layer.locked = not is_item_button_toggled
	item.set_button(column, id, off_state_texture if is_item_button_toggled else on_state_texture)


func _on_search_box_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		flat_item_list = get_flat_visible_item_list()


func _on_search_box_text_changed(new_text: String) -> void:
	filter_items(new_text)


func _on_search_box_text_submitted(layer_name: String) -> void:
	search_box.clear()
	Editor.root.level.create_layer(layer_name)


func _on_confirm_pressed() -> void:
	var layer_name: String = search_box.text
	search_box.clear()
	Editor.root.level.create_layer(layer_name)


func _on_inspector_manager_renamed_object(object: Node2D, new_name: String) -> void:
	var layer: Layer = object.get_parent()
	var layer_item: TreeItem = get_root().get_child(layer.get_index())
	var object_item: TreeItem = layer_item.get_child(object.get_index())
	object_item.set_text(0, new_name)


func _on_item_edited() -> void:
	var item: TreeItem = get_next_selected(null)
	handle_item_rename(item)
