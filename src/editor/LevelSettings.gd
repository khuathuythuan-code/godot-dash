class_name LevelSettings
extends Control

@export var song_path: FileProperty
@export var song_start_offset: FloatProperty
@export var preview_button: Button

var saveloads: Array[PropertySaveLoad]
var is_previewing: bool = false


func _ready() -> void:
	$"TabContainer/Level Settings/VBoxContainer".custom_minimum_size.y = $"TabContainer/Level Settings/VBoxContainer".size.y
	saveloads.assign(NodeUtils.get_children_of_type(self, PropertySaveLoad, true))
	await get_tree().process_frame
	refresh_saveloads(LevelManager.current_level)


func refresh_saveloads(level: Level) -> void:
	var _refresh_saveloads := func(saveload: PropertySaveLoad):
		saveload.property_owner = level
		saveload.load_value()
	saveloads.map.call_deferred(_refresh_saveloads)


func _on_close_pressed() -> void:
	Editor.shortcut_blocker = null
	hide()


func _on_preview_pressed() -> void:
	if song_path.get_value().is_empty():
		is_previewing = false
		preview_button.icon = load("res://assets/textures/icons/godot/Play.svg")
		LevelManager.level_song_player.stop()
		LevelManager.level_song_player.stream = AssetManager.load_song_threaded_get(LevelManager.current_level.song_path)
		return

	is_previewing = not is_previewing
	if is_previewing:
		preview_button.icon = load("res://assets/textures/icons/godot/Stop.svg")
		LevelManager.level_song_player.stream = AssetManager.load_song(song_path.get_value())
		LevelManager.level_song_player.play(song_start_offset.get_value())
	else:
		preview_button.icon = load("res://assets/textures/icons/godot/Play.svg")
		LevelManager.level_song_player.stop()
		LevelManager.level_song_player.stream = AssetManager.load_song_threaded_get(LevelManager.current_level.song_path)
