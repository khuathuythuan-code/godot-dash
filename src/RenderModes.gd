extends PanelContainer

class_name RenderMode

signal update_hsvwatcher

@export var object_mode: Button
@export var material_mode: Button
@export var rendered_mode: Button
@onready var buttons: Array[Button] = [object_mode, material_mode, rendered_mode]
@onready var ground_down: Sprite2D = LevelManager.ground_down.get_node("Ground")
@onready var ground_up: Sprite2D = LevelManager.ground_up.get_node("Ground")
var mode: Mode = Mode.RENDERED_MODE

enum Mode {
	OBJECT_MODE,
	MATERIAL_MODE,
	RENDERED_MODE,
}


func _ready() -> void:
	await get_tree().process_frame
	Editor.render_mode_manager = self
	object_mode.pressed.connect(enable_object_mode)
	material_mode.pressed.connect(enable_material_mode)
	rendered_mode.pressed.connect(enable_rendered_mode)
	mode = Config.default_render_mode
	update()


func _untoggle_all(exclude: Button = null) -> void:
	for button: Button in buttons:
		button.set_pressed_no_signal(false)
	exclude.set_pressed_no_signal(true)


func enable_object_mode() -> void:
	mode = Mode.OBJECT_MODE
	_untoggle_all(object_mode)
	LevelManager.game_scene.get_node("ShaderLayer").visible = false
	AssetManager.fade_enter_effect.set_shader_parameter(&"mode", "disabled")
	ground_down.self_modulate = Color.GRAY
	ground_up.self_modulate = Color.GRAY
	for background_sprite: Sprite2D in LevelManager.background_sprites:
		background_sprite.modulate = Color.GRAY
	ground_down.material.set_shader_parameter(&"ground_color", Color.WHITE)
	update_hsvwatcher.emit()


func enable_material_mode() -> void:
	mode = Mode.MATERIAL_MODE
	_untoggle_all(material_mode)
	LevelManager.game_scene.get_node("ShaderLayer").visible = false
	AssetManager.fade_enter_effect.set_shader_parameter(&"mode", "disabled")
	ground_down.self_modulate = LevelManager.current_level.default_ground_color
	ground_up.self_modulate = LevelManager.current_level.default_ground_color
	for background_sprite: Sprite2D in LevelManager.background_sprites:
		background_sprite.modulate = LevelManager.current_level.background_color
	ground_down.material.set_shader_parameter(&"ground_color", LevelManager.current_level.line_color)
	update_hsvwatcher.emit()


func enable_rendered_mode() -> void:
	mode = Mode.RENDERED_MODE
	_untoggle_all(rendered_mode)
	LevelManager.game_scene.get_node("ShaderLayer").visible = true
	AssetManager.fade_enter_effect.set_shader_parameter(&"mode", LevelManager.current_level.enter_effect)
	ground_down.self_modulate = LevelManager.current_level.default_ground_color
	ground_up.self_modulate = LevelManager.current_level.default_ground_color
	for background_sprite: Sprite2D in LevelManager.background_sprites:
		background_sprite.modulate = LevelManager.current_level.background_color
	ground_down.material.set_shader_parameter(&"ground_color", LevelManager.current_level.line_color)
	update_hsvwatcher.emit()


func update() -> void:
	match mode:
		Mode.OBJECT_MODE:
			enable_object_mode()
		Mode.MATERIAL_MODE:
			enable_material_mode()
		Mode.RENDERED_MODE:
			enable_rendered_mode()
