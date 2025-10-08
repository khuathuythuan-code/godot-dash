extends Component
class_name AllowCeilingHitComponent


func _ready() -> void:
	super()
	parent.body_entered.connect(func(player: Player): player.allow_ceiling_hit_count += 1)
	parent.body_exited.connect(func(player: Player): player.allow_ceiling_hit_count -= 1)
