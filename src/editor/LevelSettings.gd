extends Control

class_name LevelSettings

var saveloads: Array


func _ready() -> void:
	$"TabContainer/Level Settings/VBoxContainer".custom_minimum_size.y = $"TabContainer/Level Settings/VBoxContainer".size.y
	saveloads = NodeUtils.get_children_of_type(self, PropertySaveLoad, true)
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
