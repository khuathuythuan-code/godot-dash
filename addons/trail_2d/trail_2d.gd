extends Line2D

class_name Trail2D

enum Mode {
	LENGTH,
	TIME,
}

@export var mode: Mode = Mode.LENGTH
@export var length: int = 10
@export var time: float = 1.0

@onready var parent: Node = get_parent()
var offset: Vector2 = Vector2.ZERO
var add_points: bool = true


func _ready() -> void:
	offset = position
	top_level = true


func _process(delta: float) -> void:
	global_position = Vector2.ZERO
	var point: Vector2 = parent.global_position + offset
	match mode:
		Mode.LENGTH:
			if points.is_empty() or point != points[0] and get_point_count() <= length and add_points:
				add_point(point, 0)
			if get_point_count() > length / abs(Engine.time_scale) or not add_points:
				remove_point(get_point_count() - 1)
		Mode.TIME:
			var new_length: int = time / delta
			if abs(new_length - length) % 5 == 0 or abs(new_length - length) > 3:
				length = new_length
			if points.is_empty() or point != points[0] and get_point_count() <= length and add_points:
				add_point(point, 0)
			if get_point_count() > length / abs(Engine.time_scale) or not add_points:
				remove_point(get_point_count() - 1)
