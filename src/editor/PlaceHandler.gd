extends Node
class_name PlaceHandler

signal object_deleted(object: Node2D)

@export var game_scene: Node2D
@export var editor_viewport: Control
@export var edit_handler: EditHandler

var placed_object_rotation_degrees: float
var previous_pressed_button: BaseButton ## Used to detect if the block palette button changed, to reset the placed object rotation.


func handle_place(block_palette_button_group: ButtonGroup, placed_objects_collider: Area2D, level: Level) -> void:
	if not LevelManager.level_playing and get_viewport().gui_get_hovered_control() == editor_viewport and not edit_handler.gizmo:
		# Handle object placement
		var pressed_button := block_palette_button_group.get_pressed_button()
		if previous_pressed_button != pressed_button:
			placed_object_rotation_degrees = 0.0
		previous_pressed_button = pressed_button
		var block_palette_ref: BlockPaletteRef
		if pressed_button != null:
			block_palette_ref = NodeUtils.get_child_of_type(pressed_button, BlockPaletteRef) as BlockPaletteRef
		if block_palette_ref != null and not texture_variation_overlapping(placed_objects_collider, block_palette_ref.type, block_palette_ref.id) \
				and (Input.is_action_pressed(&"editor_add", false) or Config.is_touch_screen and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Editor.swipe):
			if pressed_button != null and (not Config.is_touch_screen or Editor.delete == false):
				# Create object
				var object: Node2D
				object = block_palette_ref.object.instantiate()

				if pressed_button.has_meta("texture_override"):
					var override = pressed_button.get_meta("texture_override") as TextureOverride
					if override.prefab_override:
						object.queue_free()
						object = override.prefab_override.instantiate()
					if override.base != null:
						object.get_node(^"Base").texture = override.base
					if override.detail != null:
						object.get_node(^"Detail").texture = override.detail
					object.name = override.name
					var id: int = block_palette_ref.id
					object.get_node(^"EditorSelectionCollider").id = id
					_set_texture_override_metadata(object, override, id)

				var editor_grid := game_scene.get_node("%EditorGrid") as EditorGrid
				var grid_offset_to_level_origin := Vector2(0, 64)
				object.position = (level.get_local_mouse_position() + grid_offset_to_level_origin).snapped(editor_grid.cell_size) - grid_offset_to_level_origin
				object.rotation_degrees = wrapf(placed_object_rotation_degrees, -180.0, 180.0)

				# Version history
				var add_object := func(_path_ref: PathRef):
					var _object: Node = _path_ref.to_ref()
					Editor.root.level.add_child(_object, true)
					NodeUtils.change_owner_recursive(_object, Editor.root.level)
				var remove_object := func(_path_ref: PathRef):
					var _object: Node = _path_ref.to_ref()
					_object.get_parent().remove_child(_object)
				var path_ref := PathRef.new(object)
				Editor.version_history.create_action("Placed object " + object.name)
				Editor.version_history.add_do_method(add_object.bind(path_ref))
				Editor.version_history.add_undo_method(remove_object.bind(path_ref))
				Editor.version_history.commit_action()
				add_hsv_watchers(object, level)
				edit_handler.select(Selection.from_object(object), true)

				object.material = load("res://resources/FadeEnterEffect.tres")
				for child: Object in object.get_children():
					if (child is Node2D or child is Control) and child is not PulseCircle:
						child.use_parent_material = true
		# Handle object deletion
		elif (Input.is_action_pressed(&"editor_remove", false) or Config.is_touch_screen and Editor.delete) and placed_objects_collider.has_overlapping_areas():
			placed_object_rotation_degrees = 0.0
			if len(placed_objects_collider.get_overlapping_areas()) > 0 and placed_objects_collider.get_overlapping_areas()[-1].get_parent() is not Level:
				var overlapping_areas := placed_objects_collider.get_overlapping_areas()
				object_deleted.emit(overlapping_areas[-1])
				var object := get_area(overlapping_areas[-1])

				# Version history
				var delete_object := func(_path_ref: PathRef):
					var _object: Node = _path_ref.to_ref()
					_object.get_parent().remove_child(_object)
				var restore_object := func(_path_ref: PathRef):
					var _object: Node = _path_ref.to_ref()
					Editor.root.level.add_child(_object, true)
					NodeUtils.change_owner_recursive(_object, Editor.root.level)
				var path_ref := PathRef.new(object)
				Editor.version_history.create_action("Deleted object " + object.name)
				Editor.version_history.add_do_method(delete_object.bind(path_ref))
				Editor.version_history.add_undo_method(restore_object.bind(path_ref))
				Editor.version_history.commit_action()
				edit_handler.deselect(Selection.from_object(object), true)


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


func _set_texture_override_metadata(object: Node2D, override: TextureOverride, id: int) -> void:
	var texture_override_data: Dictionary = {
		"id": id,
	}
	if override.base:
		texture_override_data.base = override.base.resource_path.trim_prefix("res://")
	if override.detail:
		texture_override_data.detail = override.detail.resource_path.trim_prefix("res://")
	object.set_meta(&"texture_override", texture_override_data)


func _on_edit_handler_rotated_object_degrees(rotation_degrees:float) -> void:
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
		hsv_watcher.set_owner(level)
