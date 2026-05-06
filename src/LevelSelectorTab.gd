@tool
extends Control

@export_file("*.json") var selected_level: String
@export var fade_screen_layer: CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Button/Label".text = name
	$Button.self_modulate = self_modulate
	$Button.material.set_shader_parameter("gui_color", self_modulate)


func _process(_delta: float) -> void:
	$TabCenter.position = Vector2(size.x / 2, size.y / 2)


func _on_button_pressed() -> void:
	if selected_level.is_empty() or not FileAccess.file_exists(selected_level):
		return
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelPlay.ogg")
	var fade_screen: FadeScreen = fade_screen_layer.get_node(^"FadeScreen")
	fade_screen.fade_in()
	await fade_screen.fade_finished
	LevelManager.current_level_name = name
	LevelManager.attempt = 0
	LevelManager.current_level_path = selected_level
	get_tree().change_scene_to_packed(AssetManager.game_scene_packed)
