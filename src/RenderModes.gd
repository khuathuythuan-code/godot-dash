extends PanelContainer

class_name RenderMode

signal update_hsvwatcher

@export var object_mode: Button
@export var material_mode: Button
@export var rendered_mode: Button
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
	match mode:
		Mode.OBJECT_MODE:
			object_mode.set_pressed(true)
		Mode.MATERIAL_MODE:
			material_mode.set_pressed(true)
		Mode.RENDERED_MODE:
			rendered_mode.set_pressed(true)


func enable_object_mode() -> void:
	LevelManager.game_scene.get_node("ShaderLayer").visible = false
	var level: Level = Editor.root.level
	level.ground_color = Color.GRAY
	level.background_color = Color.GRAY
	level.line_color = Color.WHITE
	level.enter_effect = level.enter_effect # Trigger setter
	mode = Mode.OBJECT_MODE # Locks editing of level colors
	update_hsvwatcher.emit()


func enable_material_mode() -> void:
	mode = Mode.MATERIAL_MODE
	LevelManager.game_scene.get_node("ShaderLayer").visible = false
	var level: Level = Editor.root.level
	level.ground_color = level.default_ground_color
	level.background_color = level.default_background_color
	level.line_color = level.default_line_color
	level.enter_effect = level.enter_effect # Trigger setter
	update_hsvwatcher.emit()


func enable_rendered_mode() -> void:
	mode = Mode.RENDERED_MODE
	LevelManager.game_scene.get_node("ShaderLayer").visible = true
	var level: Level = Editor.root.level
	level.ground_color = level.default_ground_color
	level.background_color = level.default_background_color
	level.line_color = level.default_line_color
	level.enter_effect = level.enter_effect # Trigger setter
	update_hsvwatcher.emit()
