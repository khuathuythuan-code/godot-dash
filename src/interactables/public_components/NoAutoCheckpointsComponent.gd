extends Component

class_name NoAutoCheckpointsComponent

func _ready() -> void:
	parent.body_entered.connect(func(player: Player): player.allow_auto_checkpoints_count += 1)
	parent.body_exited.connect(func(player: Player): player.allow_auto_checkpoints_count -= 1)
