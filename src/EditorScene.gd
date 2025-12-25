extends Control

class_name EditorScene

enum EditorAction {
	SWIPE = 1 << 0,
	ROTATE = 1 << 1,
	FREE_MOVE = 1 << 2,
	SNAP = 1 << 3,
}

@export var block_palette_button_group: ButtonGroup
@export var editor_camera: MapCamera2D
@export var view_menu: MenuBarView

var level: Level:
	set(value):
		level = value
		$EditHandler.level = value
var editor_actions: int

@onready var placed_objects_collider := $PlacedObjectsCollider as Area2D


func _enter_tree() -> void:
	SceneManager.set_current_scene(SceneManager.Scene.EDITOR)


func _ready() -> void:
	Editor.root = self
	Editor.viewport = %EditorViewport

	if SceneManager.from_title_screen():
		var _fade_screen = $FadeScreenLayer/FadeScreen
		_fade_screen.show()
		_fade_screen.modulate = Color("000000ff")
		_fade_screen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_SINE)
		create_tween().tween_property($EditorCamera, "zoom", Vector2.ONE * 0.8, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).from(Vector2.ONE * 0.4)

	LevelManager.attempt = 1
	LevelManager.level_playing = false
	$EditorCamera.enabled = true
	%EditorModes.visible = view_menu.is_item_checked(MenuBarView.BOTTOM_PANEL)
	%SidePanel.visible = view_menu.is_item_checked(MenuBarView.SIDE_PANEL)
	$GameScene/Player.process_mode = Node.PROCESS_MODE_DISABLED
	$GameScene/PlayerCamera.enabled = false
	$GameScene/PercentageLayer.hide()
	$PlaceHandler.placed_object_rotation_degrees = 0.0
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
		%ColorChannelEditor.clear_item_list()
		await get_tree().process_frame
		%ColorChannelEditor.populate_item_list()
	elif not $GameScene/Level.get_child_count():
		level = Level.new()
		level.name = "New level"
		Editor.version_history = VersionHistory.new()
		LevelManager.game_scene.add_loaded_level(level)

	if not $EditHandler.selection.is_empty():
		$EditHandler.selection.for_each(EditHandler.add_selection_highlight)


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

	get_tree().auto_accept_quit = not level_was_modified()
	$GameScene/PauseMenuLayer/PauseMenu.suspended = level_was_modified()

	if (
		%EditorModes.get_current_tab_control().name == "Place"
		and (Input.is_action_just_pressed(&"editor_add", true) or Input.is_action_just_pressed(&"editor_remove", true)
			or Input.is_action_pressed(&"editor_add_swipe", true) or Input.is_action_pressed(&"editor_remove_swipe", true) )
	):
		$PlaceHandler.handle_place(block_palette_button_group, placed_objects_collider, level)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_redo", true):
		Editor.version_history.redo()
	elif event.is_action_pressed(&"ui_undo", true):
		Editor.version_history.undo()
	elif event.is_action_pressed(&"editor_hide_panels"):
		%View.toggle_maximize_viewport()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and level_was_modified():
		process_mode = Node.PROCESS_MODE_ALWAYS
		$SaveChangesBeforeOpening.dialog_text = "Save changes before quitting?"
		$SaveChangesBeforeOpening.show()
		$SaveChangesBeforeOpening.custom_action.connect(get_tree().quit, ConnectFlags.CONNECT_ONE_SHOT)
		$LevelOperationsHandler.level_saved.connect(get_tree().quit, ConnectFlags.CONNECT_ONE_SHOT)


func texture_variation_overlapping(type: EditorSelectionCollider.Type, id: int) -> bool:
	if not placed_objects_collider.has_overlapping_areas():
		return false
	if placed_objects_collider.get_overlapping_areas()[-1].get_parent() is Interactable:
		return true
	if placed_objects_collider.get_overlapping_areas()[-1].type == type:
		return placed_objects_collider.get_overlapping_areas()[-1].id == id
	return false


func level_was_modified() -> bool:
	if not level:
		return false
	return Editor.version_history.get_version() > Editor.level_history_version


func any_dialog_is_open() -> bool:
	var dialogs := NodeUtils.get_children_of_type(self, AcceptDialog)
	for dialog in dialogs:
		if dialog.visible:
			return true
	return false


func _fade_leave(_action: Variant = null) -> void:
	$GameScene/PauseMenuLayer/PauseMenu.unsuspend()
	var _fade_screen = $FadeScreenLayer/FadeScreen
	_fade_screen.show()
	_fade_screen.fade_in(0.5, Tween.EASE_IN, Tween.TRANS_SINE)
	await create_tween().tween_property($EditorCamera, "zoom", $EditorCamera.zoom / 2, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO).finished


func _on_playtest_pressed() -> void:
	$EditorCamera.enabled = not $EditorCamera.enabled
	$GameScene/PlayerCamera.enabled = not $GameScene/PlayerCamera.enabled
	if $GameScene/PlayerCamera.enabled:
		$EditHandler.remove_gizmo()
		$EditHandler.selection.for_each(EditHandler.remove_selection_highlight)
		%ColorChannelEditor.hide_properties()
		await get_tree().process_frame
		Editor.level_data_snapshot = level.to_data()
		Editor.snapshot.pack(self)
		%MenuBarContainer.hide()
		%EditorModes.hide()
		%SidePanel.hide()
		%LevelSettings.hide()
		%EditorViewport.mouse_filter = MOUSE_FILTER_STOP
		LevelManager.player.process_mode = Node.PROCESS_MODE_INHERIT
		$GameScene/PercentageLayer.show()
		$GameScene/EditorGridParallax/EditorGrid.visible = not Config.hide_grid_on_playtest
		$LevelOperationsHandler.pause_autosave()
		$GameScene.start_level()
	else:
		%Playtest.disabled = true
		LevelManager.ground_up.hide()
		LevelManager.ground_up.position.y = GroundMoverComponent.DEFAULT_GROUND_UP_Y
		LevelManager.ground_down.position.y = GroundMoverComponent.DEFAULT_GROUND_DOWN_Y
		# Avoid multiple scene transitions
		SceneManager.set_current_scene(SceneManager.Scene.EDITOR)
		LevelManager.player.queue_free()
		LevelManager.player_duals.map(NodeUtils.free_node)
		LevelManager.player_duals.clear()
		level.queue_free()
		await get_tree().process_frame
		var new_player: Player = AssetManager.player_packed.instantiate()
		$GameScene.add_child(new_player)
		var player_camera: PlayerCamera = LevelManager.player_camera
		player_camera.player = new_player
		player_camera.center_on_player_at_0x_speed = true
		player_camera.static_factor = Vector2.ZERO
		player_camera.gameplay_offset_factor = Vector2.ONE
		player_camera.zoom = PlayerCamera.DEFAULT_ZOOM
		player_camera.offset = PlayerCamera.DEFAULT_OFFSET
		_ready() # sets `level`
		new_player.position = level.start_position
		_load_default_player_data_component(new_player.get_node(^"EditorPlayerSelectionCollider").query(DefaultPlayerDataComponent))
		%LevelSettings._on_menu_bar_handler_level_loaded(level)
		%Playtest.disabled = false


func _on_leave_pressed() -> void:
	Editor.level_data_snapshot.clear()
	Editor.level_history_version = -1
	if level_was_modified():
		$SaveChangesBeforeOpening.dialog_text = "Save changes before quitting?"
		$SaveChangesBeforeOpening.show()
		$SaveChangesBeforeOpening.custom_action.connect(_fade_leave, ConnectFlags.CONNECT_ONE_SHOT)
		$LevelOperationsHandler.level_saved.connect(_fade_leave, ConnectFlags.CONNECT_ONE_SHOT)
		return
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Title Screen")
		DiscordRPCHandler.refresh()
	_fade_leave()


func _load_default_player_data_component(component: DefaultPlayerDataComponent) -> void:
	component.platformer = level.platformer
	component.reverse = level.start_reverse
	component.speed = level.start_speed
	component.gameplay_rotation = level.start_gameplay_rotation_degrees
	component.internal = level.start_internal_gamemode
	component.displayed = level.start_displayed_gamemode
	component.freefly = level.start_freefly
