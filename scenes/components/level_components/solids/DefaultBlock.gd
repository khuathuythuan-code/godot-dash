extends StaticBody2D
@onready var last_scale: Vector2 = scale
signal _scale_changed()

func _process(delta: float) -> void:
	if last_scale == global_scale:
		last_scale = global_scale
		return
	last_scale = global_scale
	_scale_changed.emit()
