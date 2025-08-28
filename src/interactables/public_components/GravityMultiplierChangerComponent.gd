extends Component
class_name GravityMultiplierChangerComponent

signal changed(gravity_multiplier: String)

@export var gravity_multiplier: float = 1.0:
	set(value):
		gravity_multiplier = value
		changed.emit(str(gravity_multiplier))

var initial_gravity_multipliers: Dictionary[Player, float]

func _ready() -> void:
	super()
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func start(player: Player) -> void:
	initial_gravity_multipliers.set(player, player.gravity_multiplier)


func _on_easing_progressed(player: Player, weight_delta: float) -> void:
	player.gravity_multiplier += (gravity_multiplier - initial_gravity_multipliers[player]) * weight_delta

