extends Node

class_name SubsceneManager

enum SubScene {
	TITLE_SCREEN,
	LEVEL_SELECTOR,
	ICON_GARAGE,
	CREATED_LEVELS_LIST,
	SETTINGS_MENU,
}

static var editor_scene: PackedScene

@export var camera: Camera2D
@export var active_pcam: PhantomCamera2D # Active PhantomCamera2D when the scene enters the tree
@export var history: PhantomCameraHistory
@export var fade_screen_layer: CanvasLayer
@export var menu_loop: AudioStreamPlayer

@export_group("Subscenes")
@export var created_levels_list: Control
@export var level_selector: Control
@export var settings_panel: PanelContainer
@export var settings_menu: TabContainer

@export_group("PhantomCameras")
@export var quit_game_camera: PhantomCamera2D
@export var title_screen_camera: PhantomCamera2D

@export_group("Title Screen Components")
@export var title_screen_background: Parallax2D
@export var title_screen_ground: Parallax2D
@export var menu_icon: MenuIcon
@export var menu_icon_killer: MenuIconKiller

@export_group("Level Selector Components")
@export var level_selector_page_container: Control

@onready var _base_background_color: Color = title_screen_background.get_node("Background").modulate

var _current_subscene: SubScene = SubScene.TITLE_SCREEN
var _camera_tween: Tween


func _enter_tree() -> void:
	SceneManager.set_current_scene(SceneManager.Scene.TITLE_SCREEN)


func _ready() -> void:
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	created_levels_list.position.x = created_levels_list.size.x
	created_levels_list.hide()
	level_selector.hide()
	settings_panel.hide()
	await settings_menu.ready
	if SceneManager.from_editor():
		_on_go_to_created_levels_list_pressed()
	if not SceneManager.from_title_screen():
		# HACK: Manual animation because PhantomCamera gets in the way
		camera.global_position = active_pcam.global_position
		camera.get_node(^"PhantomCameraHost").queue_free()
		var _fade_screen = fade_screen_layer.get_child(0)
		_fade_screen.fade_out(0.5, Tween.EASE_OUT, Tween.TRANS_SINE)
		_camera_tween = create_tween()
		(
			_camera_tween.tween_property(camera, "zoom", Vector2.ONE, 0.5).from(Vector2.ONE * 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		)
		await _camera_tween.finished
		camera.add_child(PhantomCameraHost.new())
	else:
		active_pcam.set_priority(PhantomCameraHistory.Status.CURRENT_ACTIVE)
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Title Screen")
		DiscordRPCHandler.refresh()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not (_camera_tween and _camera_tween.is_running()):
		if _current_subscene == SubScene.TITLE_SCREEN:
			_on_quit_game_pressed()
		else:
			_return_to_title_screen()


func _return_to_title_screen() -> void:
	_toggle_background_sprites_autoscroll(true)
	_current_subscene = SubScene.TITLE_SCREEN
	_change_background_color(_base_background_color)
	created_levels_list.hide()
	level_selector.hide()
	settings_panel.hide()


func _toggle_background_sprites_autoscroll(enabled: bool) -> void:
	menu_icon.visible = enabled
	menu_icon_killer.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	# HACK: autoscroll can't be interpolated
	if enabled:
		title_screen_background.autoscroll.x = -300
		title_screen_ground.autoscroll.x = -800
	else:
		title_screen_background.autoscroll.x = 0
		title_screen_ground.autoscroll.x = 0


func _change_background_color(new_color: Color) -> void:
	create_tween() \
	.tween_property(title_screen_background.get_node("Background"), "modulate", new_color, 1.0) \
	.set_ease(Tween.EASE_OUT) \
	.set_trans(Tween.TRANS_EXPO)


func _on_go_to_level_selector_pressed() -> void:
	if level_selector.visible:
		_return_to_title_screen()
		return
	_return_to_title_screen()
	level_selector.show()
	_current_subscene = SubScene.LEVEL_SELECTOR


func _on_go_to_created_levels_list_pressed() -> void:
	created_levels_list.show()
	level_selector.hide()
	_current_subscene = SubScene.CREATED_LEVELS_LIST
	_toggle_background_sprites_autoscroll(false)


func _on_settings_pressed() -> void:
	if settings_panel.visible:
		_return_to_title_screen()
		return
	_return_to_title_screen()
	settings_panel.show()
	_current_subscene = SubScene.SETTINGS_MENU


func _on_editor_pressed() -> void:
	var _fade_screen = fade_screen_layer.get_child(0)
	if not _fade_screen.is_fading:
		$"../MenuLoop".playing = false
		SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelPlay.ogg")
		_fade_screen.fade_in(0.5, Tween.EASE_IN, Tween.TRANS_SINE)
		await _fade_screen.fade_finished
		if DiscordRPCManager.available:
			DiscordRPCHandler.set_details("Creating a level")
			DiscordRPCHandler.refresh()
		if Editor.snapshot.can_instantiate():
			get_tree().change_scene_to_packed(Editor.snapshot)
		else:
			get_tree().change_scene_to_packed(AssetManager.editor_packed)


func _on_quit_game_pressed() -> void:
	var _fade_screen = fade_screen_layer.get_child(0)
	if not _fade_screen.is_fading:
		_fade_screen.fade_in(0.5, Tween.EASE_IN_OUT, Tween.TRANS_EXPO)
		history.change_phantomcamera(active_pcam, quit_game_camera)
		await _fade_screen.fade_finished
		get_tree().quit()


func _on_back_button_pressed() -> void:
	_return_to_title_screen()
