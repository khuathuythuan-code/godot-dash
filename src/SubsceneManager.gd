class_name SubsceneManager
extends Node

enum SubScene {
	TITLE_SCREEN,
	LEVEL_SELECTOR,
	ICON_GARAGE,
	COMMUNITY_MENU,
	SETTINGS_MENU,
}

static var editor_scene: PackedScene
static var is_first_load: bool = true

@export var camera: Camera2D
@export var active_pcam: PhantomCamera2D # Active PhantomCamera2D when the scene enters the tree
@export var history: PhantomCameraHistory
@export var fade_screen: FadeScreen
@export var menu_loop: AudioStreamPlayer
@export var splash: Control

@export_group("Subscenes")
@export var level_selector: TitleScreenPanel
@export var community_menu: TitleScreenPanel
@export var icon_garage: TitleScreenPanel
@export var settings_panel: TitleScreenPanel
@export var settings_menu: TabContainer

@export_group("PhantomCameras")
@export var quit_game_camera: PhantomCamera2D
@export var title_screen_camera: PhantomCamera2D
@export var from_editor_camera: PhantomCamera2D

@export_group("Title Screen Components")
@export var title_screen_layer: CanvasLayer
@export var title_screen_background: Parallax2D
@export var title_screen_ground: Parallax2D
@export var menu_icon: MenuIcon
@export var menu_icon_killer: MenuIconKiller

@onready var _base_background_color: Color = title_screen_background.get_node("Background").modulate

var _current_subscene: SubScene = SubScene.TITLE_SCREEN
var _camera_tween: Tween


func _enter_tree() -> void:
	SceneManager.set_current_scene(SceneManager.Scene.TITLE_SCREEN)


func _ready() -> void:
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	community_menu.hide()
	level_selector.hide()
	settings_panel.hide()
	if SceneManager.from_editor() or SceneManager.from_level():
		community_menu.position = community_menu.inital_position
		community_menu.show()
	if not SceneManager.from_title_screen():
		# HACK: Manual animation because PhantomCamera gets in the way
		camera.global_position = active_pcam.global_position
		camera.get_node(^"PhantomCameraHost").queue_free()
		fade_screen.fade_out()
		_camera_tween = create_tween()
		(
			_camera_tween \
			.tween_property(camera, ^"zoom", PlayerCamera.DEFAULT_ZOOM, Config.transition_duration) \
			.from(Vector2.ONE * 2) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_EXPO)
		)
		zoom_out_title_screen_layer()
		await _camera_tween.finished
		camera.add_child(PhantomCameraHost.new())
	else:
		active_pcam.set_priority(PhantomCameraHistory.Status.CURRENT_ACTIVE)
	if Config.transition_duration > 0.0 and is_first_load:
		splash.show()
		var splash_tween: Tween = create_tween()
		(
			splash_tween \
			.tween_property(splash, ^"modulate:a", 0.0, Config.transition_duration) \
			.set_ease(Tween.EASE_IN_OUT) \
			.set_trans(Tween.TRANS_SINE)
		)
		splash_tween.tween_callback(splash.hide)
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Title Screen")
		DiscordRPCHandler.refresh()
	await ready
	quit_game_camera.set_tween_duration(Config.transition_duration)
	title_screen_camera.set_tween_duration(Config.transition_duration)
	from_editor_camera.set_tween_duration(Config.transition_duration)
	is_first_load = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not (_camera_tween and _camera_tween.is_running()):
		if _current_subscene == SubScene.TITLE_SCREEN:
			_on_quit_game_pressed()
		else:
			_return_to_title_screen()


func zoom_in_title_screen_layer() -> void:
	var tween: Tween = create_tween().set_parallel().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(title_screen_layer, ^"scale", Vector2.ONE * 4.0, Config.transition_duration)
	tween.tween_property(title_screen_layer, ^"offset", -camera.get_viewport_rect().size * sqrt(2.0), Config.transition_duration)


func zoom_out_title_screen_layer() -> void:
	var tween: Tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(title_screen_layer, ^"scale", Vector2.ONE, Config.transition_duration).from(Vector2.ONE * 2.0)
	tween.tween_property(title_screen_layer, ^"offset", Vector2.ZERO, Config.transition_duration).from(-camera.get_viewport_rect().size / 2.0)


func _return_to_title_screen() -> void:
	_toggle_background_sprites_autoscroll(true)
	_current_subscene = SubScene.TITLE_SCREEN
	_change_background_color(_base_background_color)
	for object in [level_selector, community_menu, settings_panel, icon_garage]:
		if object.visible:
			object.hide_tween()


func _toggle_background_sprites_autoscroll(enabled: bool) -> void:
	if Config.enable_title_screen_icons:
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
	level_selector.show_tween()
	_current_subscene = SubScene.LEVEL_SELECTOR


func _on_go_to_community_menu_pressed() -> void:
	if community_menu.visible:
		_return_to_title_screen()
		return
	_return_to_title_screen()
	community_menu.show_tween()
	_current_subscene = SubScene.COMMUNITY_MENU


func _on_go_to_icon_garage_pressed() -> void:
	if icon_garage.visible:
		_return_to_title_screen()
		return
	_return_to_title_screen()
	icon_garage.show_tween()
	_current_subscene = SubScene.ICON_GARAGE


func _on_settings_pressed() -> void:
	if settings_panel.visible:
		_return_to_title_screen()
		return
	_return_to_title_screen()
	settings_panel.show_tween()
	_current_subscene = SubScene.SETTINGS_MENU


func _on_editor_pressed() -> void:
	if fade_screen.is_fading:
		return
	$"../MenuLoop".playing = false
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelPlay.ogg")
	history.change_phantomcamera(active_pcam, quit_game_camera)
	zoom_in_title_screen_layer()
	fade_screen.fade_in()
	await fade_screen.fade_finished
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Creating a level")
		DiscordRPCHandler.refresh()
	get_tree().change_scene_to_packed(AssetManager.editor_packed)


func _on_quit_game_pressed() -> void:
	if fade_screen.is_fading:
		return
	fade_screen.fade_in()
	history.change_phantomcamera(active_pcam, quit_game_camera)
	zoom_in_title_screen_layer()
	await fade_screen.fade_finished
	get_tree().quit()


func _on_back_button_pressed() -> void:
	_return_to_title_screen()
