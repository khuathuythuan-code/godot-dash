extends Control
class_name EditorScene

enum EditorAction {
	SWIPE     = 1 << 0,
	ROTATE    = 1 << 1,
	FREE_MOVE = 1 << 2,
	SNAP      = 1 << 3,
}

const DEFAULT_PLAYER_POSITION: Vector2 = Vector2(640.0, 860.0)

static var player_prefab: PackedScene

@export var block_palette_button_group: ButtonGroup
@export var editor_camera: MapCamera2D
@export var view_menu: MenuBarView

var level: Level:
	set(value):
		level = value
		$EditHandler.level = value
var editor_actions: int

@onready var placed_objects_collider := $PlacedObjectsCollider as Area2D


func _ready() -> void:
	ResourceLoader.load_threaded_request("res://scenes/components/game_components/Player.tscn")
	Editor.root = self
	if SceneTransition.from_main():
		SceneTransition.previous = SceneTransition.Scene.EDITOR
		var _fade_screen = $FadeScreenLayer/FadeScreen
		_fade_screen.show()
		_fade_screen.modulate = Color("000000ff")
		_fade_screen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_SINE)
		create_tween().tween_property($EditorCamera, "zoom", Vector2.ONE * 0.8, 0.5)\
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_EXPO) \
				.from(Vector2.ONE * 0.4)
	
	LevelManager.attempt = 1
	LevelManager.level_playing = false
	$EditorCamera.enabled = true
	%EditorModes.visible = view_menu.is_item_checked(MenuBarView.BOTTOM_PANEL)
	%SidePanel.visible = view_menu.is_item_checked(MenuBarView.SIDE_PANEL)
	$GameScene/Player.process_mode = Node.PROCESS_MODE_DISABLED
	$GameScene/PlayerCamera.enabled = false
	$GameScene/PercentageLayer.hide()
	var editor_grid: EditorGrid = $GameScene/EditorGridParallax/EditorGrid
	editor_grid.visible = view_menu.is_item_checked(MenuBarView.GRID)
	if editor_grid.visible:
		editor_grid.queue_redraw()
	NodeUtils.connect_once($GameScene/PauseMenuLayer/PauseMenu.leave, _on_leave_pressed)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	NodeUtils.connect_once($EditorCamera.zoom_changed, $GameScene/EditorGridParallax/EditorGrid.queue_redraw)
	$EditHandler.placed_objects_collider = placed_objects_collider
	$EditHandler.editor_mode = %EditorModes
	%MenuBarContainer.show()

	if not Editor.level_data_snapshot.is_empty():
		level = LevelManager.game_scene.add_loaded_level(Level.from_data(Editor.level_data_snapshot)) 
	elif not $GameScene/Level.get_child_count():
		level = Level.new()
		level.name = "New level"
		level.version_history = UndoRedo.new()
		LevelManager.game_scene.add_loaded_level(level)


func _physics_process(_delta: float) -> void:
	if LevelManager.level_playing:
		return
	placed_objects_collider.global_position = get_local_mouse_position()
	if not Editor.is_text_input_focused() and not any_dialog_is_open() and not $EditHandler.any_gizmo_is_open():
		if Input.is_action_just_pressed(&"editor_place_mode"):
			%EditorModes.current_tab = 0
		elif Input.is_action_just_pressed(&"editor_edit_mode"):
			%EditorModes.current_tab = 1
		elif Input.is_action_just_pressed(&"editor_selection_filters_mode"):
			%EditorModes.current_tab = 2

	if %EditorModes.get_current_tab_control().name == "Place" \
			and (Input.is_action_just_pressed(&"editor_add", true) or Input.is_action_just_pressed(&"editor_remove", true) \
			or Input.is_action_pressed(&"editor_add_swipe", true) or Input.is_action_pressed(&"editor_remove_swipe", true)):
		$PlaceHandler.handle_place(block_palette_button_group, placed_objects_collider, level)


func texture_variation_overlapping(type: EditorSelectionCollider.Type, id: int) -> bool:
	if not placed_objects_collider.has_overlapping_areas():
		return false
	if placed_objects_collider.get_overlapping_areas()[-1].get_parent() is Interactable:
		return true
	if placed_objects_collider.get_overlapping_areas()[-1].type == type:
		return placed_objects_collider.get_overlapping_areas()[-1].id == id
	return false


func level_was_modified() -> bool:
	# TODO: Create action history using UndoRedo
	return level.get_child_count() > 1


func any_dialog_is_open() -> bool:
	var dialogs := NodeUtils.get_children_of_type(self, AcceptDialog)
	for dialog in dialogs:
		if dialog.visible:
			return true
	return false


func _on_playtest_pressed() -> void:
	$EditorCamera.enabled = not $EditorCamera.enabled
	$GameScene/PlayerCamera.enabled = not $GameScene/PlayerCamera.enabled
	if $GameScene/PlayerCamera.enabled:
		if not $EditHandler.selection.is_empty():
			$EditHandler.selection.map(EditHandler.remove_selection_highlight)
			$EditHandler.selection.clear()
		%ColorChannelEditor.hide_properties()
		await get_tree().process_frame
		Editor.level_data_snapshot = level.to_data()
		Editor.snapshot.pack(self)
		%MenuBarContainer.hide()
		%EditorModes.hide()
		%SidePanel.hide()
		%LevelSettings.hide()
		%EditorViewport.mouse_filter = MOUSE_FILTER_STOP
		$GameScene/Player.process_mode = Node.PROCESS_MODE_INHERIT
		$GameScene/PercentageLayer.show()
		$GameScene/EditorGridParallax/EditorGrid.visible = not Config.hide_grid_on_playtest
		$LevelOperationsHandler.pause_autosave()
		$GameScene.start_level()
	else:
		LevelManager.player.queue_free()
		LevelManager.player_duals.map(NodeUtils.free_node)
		LevelManager.player_duals.clear()
		level.queue_free()
		await get_tree().process_frame
		player_prefab = ResourceLoader.load_threaded_get("res://scenes/components/game_components/Player.tscn")
		var new_player: Player = player_prefab.instantiate()
		new_player.position = DEFAULT_PLAYER_POSITION
		$GameScene.add_child(new_player)
		LevelManager.player_camera.player = new_player
		LevelManager.player_camera.static_factor = Vector2.ZERO
		_ready()
		%LevelSettings._on_menu_bar_handler_level_loaded(level)


func _on_leave_pressed() -> void:
	if not LevelManager.level_playing:
		$EditHandler.selection.map($EditHandler.remove_selection_highlight)
		$EditHandler.selection.clear()
		Editor.level_data_snapshot = level.to_data()
		Editor.snapshot.pack(self)
	var _fade_screen = $FadeScreenLayer/FadeScreen
	_fade_screen.show()
	_fade_screen.fade_in(0.5, Tween.EASE_IN, Tween.TRANS_SINE)
	create_tween().tween_property($EditorCamera, "zoom", $EditorCamera.zoom / 2, 0.5) \
			.set_ease(Tween.EASE_IN) \
			.set_trans(Tween.TRANS_EXPO)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_redo"):
		level.version_history.redo()
	elif event.is_action_pressed(&"ui_undo"):
		level.version_history.undo()
	elif event.is_action_pressed(&"editor_hide_panels"):
		%View.toggle_maximize_viewport()
