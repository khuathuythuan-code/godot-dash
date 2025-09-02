extends CanvasLayer

@export var label: Label


func _process(_delta: float) -> void:
	if LevelManager.current_level.level_duration > 0:
		var time_since_level_start := Time.get_ticks_msec() - LevelManager.current_level.level_start_time
		var percentage := (time_since_level_start / LevelManager.current_level.level_duration) * 100.0
		percentage = clampf(percentage, 0.0, 100.0)
		label.text = "%.2f%%" % percentage
	else:
		label.text = "Infinite"
