extends CanvasLayer

@export var label: Label


func _process(_delta: float) -> void:
	if is_zero_approx(LevelManager.current_level.level_duration):
		label.text = "Infinite"
	else:
		var time_since_level_start := LevelManager.current_level.stopwatch.get_elapsed_time_in_seconds()
		var percentage := (time_since_level_start / LevelManager.current_level.level_duration) * 100.0
		percentage = clampf(percentage, 0.0, 100.0)
		label.text = "%.2f%%" % percentage
