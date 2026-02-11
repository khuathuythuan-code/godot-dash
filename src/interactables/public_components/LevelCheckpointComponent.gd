extends Component

class_name LevelCheckpointComponent

func _ready() -> void:
	parent.interacted.connect(place_checkpoint)


func place_checkpoint(player: Player) -> void:
	var player_just_respawned: bool = LevelManager.current_level.stopwatch.elapsed_time < get_process_delta_time()
	if not player_just_respawned:
		player.place_checkpoint().done()
