extends Node

class_name PathFollowSpeed

func _ready() -> void:
	var parent := get_parent() as FireDashComponent
	parent.path = self


func get_velocity(player: Player) -> Vector2:
	print_debug("TODO: implement PathFollowSpeed")
	return Vector2.ZERO
