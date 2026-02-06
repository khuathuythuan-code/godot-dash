extends Component

class_name AutoCheckpointComponent

@export var practice_only: bool = true


func _ready() -> void:
	parent.interacted.connect(func(player: Player): 
		if (LevelManager.practice_mode and practice_only) or not practice_only:
			player.place_checkpoint(true)
		)
