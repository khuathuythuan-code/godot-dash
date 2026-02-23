extends Component

class_name NoAutoCheckpointsComponent

func _ready() -> void:
	parent.body_entered.connect(func(player: Player): player.disable_auto_checkpoints += 1)
	parent.body_exited.connect(func(player: Player): player.disable_auto_checkpoints -= 1)
