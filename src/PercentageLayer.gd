extends CanvasLayer

@export var label: Label

var percentage: float
var end_level_x: float = 0.0

func _ready() -> void:
	LevelManager.level_started.connect(_find_end_level_trigger)
	
	
func _find_end_level_trigger() -> void:
	end_level_x = 0.0
	var level = LevelManager.current_level
	if not level:
		return
	
	for data in level.layers:
		for object in data.get_children():
			if object.name.contains("EndLevelTrigger"):
				end_level_x = object.global_position.x
				return

func _process(_delta: float) -> void:
	if not LevelManager.current_level:
		return
	if is_zero_approx(end_level_x):
		label.text = ""
		return
	if not LevelManager.player.dead:
		var start_x: float = LevelManager.current_level.start_position.x
		var player_x: float = LevelManager.player.global_position.x
		percentage = (player_x - start_x) / (end_level_x - start_x) * 100.0
		percentage = clampf(percentage, 0.0, 100.0)
		label.text = "%.2f%%" % percentage


#func _process(_delta: float) -> void:
	#if not LevelManager.current_level:
		#return
	#if is_zero_approx(LevelManager.current_level.duration):
		#label.text = "Infinite"
	#elif not LevelManager.player.dead:
		#var time_since_level_start: float = LevelManager.current_level.stopwatch.get_elapsed_time_in_seconds()
		#percentage = (time_since_level_start / LevelManager.current_level.duration) * 100.0
		#percentage = clampf(percentage, 0.0, 100.0)
		#label.text = "%.2f%%" % percentage
