class_name PlaceHandler
extends Node

signal object_deleted(object: Node2D)

@export var game_scene: Node2D
@export var editor_viewport: EditorViewport
@export var edit_handler: EditHandler

var placed_object_rotation_degrees: float
var previous_pressed_button: BaseButton ## Used to detect if the block palette button changed, to reset the placed object rotation.


func handle_place(block_palette_button_group: ButtonGroup, placed_objects_collider: Area2D, level: Level) -> void:
	if LevelManager.level_playing or get_viewport().gui_get_hovered_control() != editor_viewport or edit_handler.any_gizmo_is_open():
		return
	# Handle object placement
	var pressed_button := block_palette_button_group.get_pressed_button()
	if previous_pressed_button != pressed_button:
		placed_object_rotation_degrees = 0.0
	previous_pressed_button = pressed_button
	var block_palette_ref: BlockPaletteRef
	if pressed_button:
		block_palette_ref = NodeUtils.get_child_of_type(pressed_button, BlockPaletteRef) as BlockPaletteRef
	if (
		block_palette_ref
		and not texture_variation_overlapping(placed_objects_collider, block_palette_ref.type, block_palette_ref.id)
		and (
			Input.is_action_pressed(&"editor_add", false)
			or Config.is_touch_screen
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			and not Editor.swipe
		)
	):
		if Config.is_touch_screen and Editor.delete:
			return
		# Create object
		var object: Node2D
		object = block_palette_ref.object.instantiate()

		if pressed_button.has_meta(Constants.TEXTURE_OVERRIDE_META):
			var override = pressed_button.get_meta(Constants.TEXTURE_OVERRIDE_META) as TextureOverride
			if override.prefab_override:
				object.queue_free()
				object = override.prefab_override.instantiate()
			var target_scale = override.scale_factor
			if target_scale == Vector2.ONE and override.base:
				target_scale = Vector2.ONE * Constants.CELL_SIZE / override.base.get_size()
			var base_node = object.get_node_or_null(^"Base")
			if base_node:
				if override.base:
					base_node.texture = override.base
				if base_node is Sprite2D:
					base_node.scale = target_scale
			var detail_node = object.get_node_or_null(^"Detail")
			if detail_node:
				if override.detail:
					detail_node.texture = override.detail
				if detail_node is Sprite2D:
					detail_node.scale = target_scale
				
			object.name = override.name
			var id: int = block_palette_ref.id
			var collider = object.get_node_or_null(^"EditorSelectionCollider")
			if collider:
				collider.id = id
			_set_texture_override_metadata(object, override, id, target_scale)

		var editor_grid := game_scene.get_node("%EditorGrid") as EditorGrid
		var grid_offset_to_level_origin := Vector2(0, 64)
		object.position = (level.get_local_mouse_position() + grid_offset_to_level_origin).snapped(editor_grid.cell_size) - grid_offset_to_level_origin
		object.rotation_degrees = wrapf(placed_object_rotation_degrees, -180.0, 180.0)

		var active_layer: Layer = Editor.root.level.layers[Editor.root.level.active_layer_idx]
		object.set_meta(Constants.LAYER_META, active_layer)

		# Version history
		var add_object := func():
			active_layer.add_child(object, true)
			NodeUtils.change_owner_recursive(object, Editor.root.level)
		var remove_object := func():
			object.get_parent().remove_child(object)

		Editor.version_history.create_action("Placed object " + object.name)
		Editor.version_history.add_do_method(add_object)
		Editor.version_history.add_undo_method(remove_object)
		Editor.version_history.commit_action()

		add_hsv_watchers(object, level)
		@warning_ignore("static_called_on_instance")
		edit_handler.select(Editor.selection_from_object(object), true)

		for child: Node in object.get_children():
			Level.apply_enter_effect(child)
	# Handle object deletion
	elif (
		(
			Input.is_action_pressed(&"editor_remove", false)
			or (Config.is_touch_screen and Editor.delete)
		)
		and placed_objects_collider.has_overlapping_areas()
	):
		placed_object_rotation_degrees = 0.0
		if len(placed_objects_collider.get_overlapping_areas()) > 0 and placed_objects_collider.get_overlapping_areas()[-1].get_parent() is not Level:
			var overlapping_areas := placed_objects_collider.get_overlapping_areas()
			object_deleted.emit(overlapping_areas[-1])
			var object: Node = get_area(overlapping_areas[-1])
			var index: int = object.get_index()

			# Version history
			var delete_object := func():
				object.get_parent().remove_child(object)
			var restore_object := func():
				var layer: Layer = object.get_meta(Constants.LAYER_META)
				if not layer:
					return
				layer.add_child(object)
				layer.move_child(object, index)
				NodeUtils.change_owner_recursive(object, Editor.root.level)

			Editor.version_history.create_action("Deleted object " + object.name)
			Editor.version_history.add_do_method(delete_object)
			Editor.version_history.add_undo_method(restore_object)
			Editor.version_history.commit_action()
			@warning_ignore("static_called_on_instance")
			edit_handler.deselect(Editor.selection_from_object(object), true)
			object_deleted.emit(object)


func get_area(area: Area2D) -> Node:
	return area if area is Interactable else area.get_parent()


func texture_variation_overlapping(placed_objects_collider: Area2D, type: EditorSelectionCollider.Type, id: int) -> bool:
	if not placed_objects_collider.has_overlapping_areas():
		return false
	var overlapping_areas := placed_objects_collider.get_overlapping_areas()
	var is_interactable_or_trigger_base := func(area_parent): return area_parent is Interactable
	if not overlapping_areas.map(get_area).filter(is_interactable_or_trigger_base).is_empty():
		return true
	if placed_objects_collider.get_overlapping_areas()[-1].type == type:
		return placed_objects_collider.get_overlapping_areas()[-1].id == id
	return false


func _set_texture_override_metadata(object: Node2D, override: TextureOverride, id: int, target_scale: Vector2) -> void:
	var texture_override_data: Dictionary = {
		"id": id,
		"scale_factor": [target_scale.x, target_scale.y]
	}
	if override.base:
		texture_override_data.base = override.base.resource_path.trim_prefix("res://")
	if override.detail:
		texture_override_data.detail = override.detail.resource_path.trim_prefix("res://")
	object.set_meta(Constants.TEXTURE_OVERRIDE_META, texture_override_data)


func _on_edit_handler_rotated_object_degrees(rotation_degrees: float) -> void:
	placed_object_rotation_degrees += rotation_degrees


func _on_edit_handler_deleted_selection() -> void:
	placed_object_rotation_degrees = 0.0


static func add_hsv_watchers(object: Node2D, level: Level) -> void:
	var to_be_colored: Array = [object]
	var base: Node2D = object.get_node_or_null(^"Base")
	var detail: Node2D = object.get_node_or_null(^"Detail")
	if base:
		to_be_colored.append(base)
	if detail:
		to_be_colored.append(detail)
	for object_to_be_colored in to_be_colored:
		var hsv_watcher := HSVWatcher.new()
		hsv_watcher.name = "HSVWatcher"
		object_to_be_colored.add_child(hsv_watcher)
		   # Chỉ set_owner khi level đã trong scene tree (editor)
		if level.is_inside_tree():
			hsv_watcher.set_owner(level)
