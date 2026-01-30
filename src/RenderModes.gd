extends PanelContainer

class_name RenderMode

@export var enum_button: EnumButton
@export var fold_button: Button
@export var options_panel: PanelContainer
@export var options_panel_vbox: VBoxContainer
@export var object_segment: Control
@export_group("Properties")
@export var background_color_selector: ColorProperty
var mode: Mode = Mode.RENDERED_MODE

enum Mode {
	OBJECT_MODE,
	MATERIAL_MODE,
	RENDERED_MODE,
	TEMP,
}


func _ready() -> void:
	await get_tree().process_frame
	toggle_render_mode_options(false)
	Editor.render_mode_manager = self
	enum_button.value_changed.connect(
		func(enum_variant: int):
			update(enum_variant)
	)
	background_color_selector.set_value_no_signal(Color.GRAY)
	background_color_selector.value_changed.connect(
		func(value: Color):
			if mode == Mode.OBJECT_MODE:
				mode = Mode.TEMP
				Editor.root.level.background_color = value
				mode = Mode.OBJECT_MODE
	)
	mode = Config.default_render_mode
	enum_button.set_value_no_signal(mode)


func update(_mode: Mode = mode) -> void:
	match _mode:
		Mode.OBJECT_MODE:
			enable_object_mode()
		Mode.MATERIAL_MODE:
			enable_material_mode()
		Mode.RENDERED_MODE:
			enable_rendered_mode()
	if fold_button.button_pressed:
		toggle_render_mode_options(false, false)
		toggle_render_mode_options(true, false)


func enable_object_mode() -> void:
	LevelManager.game_scene.get_node(^"ShaderLayer").visible = false
	var level: Level = Editor.root.level
	level.ground_color = Color.GRAY
	level.background_color = background_color_selector.get_value()
	level.line_color = Color.WHITE
	level.enter_effect = level.enter_effect # Trigger setter
	mode = Mode.OBJECT_MODE # Locks editing of level colors
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


func toggle_render_mode_options(value: bool, animate: bool = true) -> void:
	if value:
		options_panel.get_node(^"MarginContainer").show()
		$VBoxContainer.add_theme_constant_override("separation", 4)
		options_panel.show()
		if animate:
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(fold_button.get_node(^"TextureRect"), "rotation_degrees", -90.0, 0.25).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			tween.tween_property(options_panel, "custom_minimum_size:y", 128, 0.25).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		match mode:
			Mode.OBJECT_MODE:
				object_segment.show()
	else:
		for child in options_panel_vbox.get_children():
			if child is VBoxContainer:
				child.hide()
		options_panel.get_node(^"MarginContainer").hide()
		$VBoxContainer.add_theme_constant_override("separation", 0)
		if animate:
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(fold_button.get_node(^"TextureRect"), "rotation_degrees", 0.0, 0.25).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			tween.tween_property(options_panel, "custom_minimum_size:y", 0, 0.25).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			await tween.finished
		options_panel.hide()
