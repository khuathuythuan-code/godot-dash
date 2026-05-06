class_name GravityMultiplierChangerComponent
extends Component

signal changed(gravity_multiplier: String)

@export_range(0.0, 2.0, 0.01, "or_greater", "or_less", "slider") var gravity_multiplier: float = 1.0:
	set(value):
		gravity_multiplier = value
		changed.emit("%.f%%" % (gravity_multiplier * 100))

@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var initial_gravity_multipliers: Dictionary[Player, float]


func _ready() -> void:
	await require([EasingComponent])
	changed.emit("%.f%%" % (gravity_multiplier * 100))
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _field_to_data(field_name: String) -> Variant:
	match field_name:
		"initial_alphas":
			var _initial_gravity_multipliers: Dictionary[NodePath, float] = { }
			for player: Player in initial_gravity_multipliers:
				_initial_gravity_multipliers[Serialize.Node(player)] = initial_gravity_multipliers[player]
			return _initial_gravity_multipliers
		_:
			return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	match field_name:
		"initial_alphas":
			for path: NodePath in field_data:
				initial_gravity_multipliers[Deserialize.Node(path) as Player] = field_data[path]
		_:
			set(field_name, field_data)


func start(player: Player) -> void:
	initial_gravity_multipliers.set(player, player.gravity_multiplier)


func _on_easing_progressed(player: Player, weight_delta: float) -> void:
	player.gravity_multiplier += (gravity_multiplier - initial_gravity_multipliers[player]) * weight_delta
