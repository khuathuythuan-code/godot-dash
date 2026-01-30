extends PanelContainer

class_name RenderMode

@export var enum_button: EnumButton
var mode: Mode = Mode.RENDERED_MODE

enum Mode {
	OBJECT_MODE,
	MATERIAL_MODE,
	RENDERED_MODE,
}


func _ready() -> void:
	await get_tree().process_frame
	Editor.render_mode_manager = self
	enum_button.value_changed.connect(
		func(enum_variant: int):
			match enum_variant:
				Mode.OBJECT_MODE:
					enable_object_mode()
				Mode.MATERIAL_MODE:
					enable_material_mode()
				Mode.RENDERED_MODE:
					enable_rendered_mode()
	)
	mode = Config.default_render_mode
	enum_button.set_value_no_signal(mode)


func enable_object_mode() -> void:
	LevelManager.game_scene.get_node(^"ShaderLayer").visible = false
	var level: Level = Editor.root.level
	level.ground_color = Color.GRAY
	level.background_color = Color.GRAY
	level.line_color = Color.WHITE
	mode = Mode.OBJECT_MODE # Locks editing of level colors
	level.enter_effect = level.enter_effect # Trigger setter
	LevelManager.update_hsv_watchers.emit()


func enable_material_mode() -> void:
	mode = Mode.MATERIAL_MODE
	LevelManager.game_scene.get_node(^"ShaderLayer").visible = false
	var level: Level = Editor.root.level
	level.ground_color = level.default_ground_color
	level.background_color = level.default_background_color
	level.line_color = level.default_line_color
	level.enter_effect = level.enter_effect # Trigger setter
	LevelManager.update_hsv_watchers.emit()


func enable_rendered_mode() -> void:
	mode = Mode.RENDERED_MODE
	LevelManager.game_scene.get_node(^"ShaderLayer").visible = true
	var level: Level = Editor.root.level
	level.ground_color = level.default_ground_color
	level.background_color = level.default_background_color
	level.line_color = level.default_line_color
	level.enter_effect = level.enter_effect # Trigger setter
	LevelManager.update_hsv_watchers.emit()
