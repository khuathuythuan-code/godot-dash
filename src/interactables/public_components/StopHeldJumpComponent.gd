extends Component

class_name StopHeldJumpComponent

func _ready() -> void:
	parent.interacted.connect(stop_held_jump)


func stop_held_jump(player: Player) -> void:
	player.jump_hold_disabled = true
