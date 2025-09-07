extends Component
class_name StopDashComponent


func _ready() -> void:
	super()
	parent.interacted.connect(stop_dash)


func stop_dash(player: Player) -> void:
	player.stop_dash()
