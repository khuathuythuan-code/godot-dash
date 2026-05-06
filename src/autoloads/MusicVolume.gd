extends Node

@onready var _spectrum := AudioServer.get_bus_effect_instance(AudioServer.get_bus_index(&"Music"), 0)


func get_volume() -> float:
	if Editor.in_editor and not LevelManager.level_playing:
		return 0.15
	return _spectrum.get_magnitude_for_frequency_range(20, 20000).length() * 0.6
