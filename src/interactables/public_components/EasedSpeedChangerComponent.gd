extends Component
class_name EasedSpeedChangerComponent

signal changed(speed: String)

enum SpeedPreset {
	x0,
	x05,
	x1,
	x2,
	x3,
	x4,
	x5,
	MANUAL,
}

const SPEED_PRESET_LABELS: PackedStringArray = ["x0.0", "x0.5", "x1.0", "x2.0", "x3.0", "x4.0", "x5.0"]

@export_enum("x0.0", "x0.5", "x1.0", "x2.0", "x3.0", "x4.0", "x5.0", "Manual speed") var speed_preset: int = SpeedPreset.x1:
	set(value):
		speed_preset = value
		speed = LevelProps.START_SPEED[speed_preset] if speed_preset != SpeedPreset.MANUAL else _manual_speed
		notify_property_list_changed()

@export_range(0.01, 2.0, 0.01, "or_greater") var speed: float = 1.0:
	set(value):
		speed = value
		if speed_preset == SpeedPreset.MANUAL:
			_manual_speed = value
			changed.emit("%.f%%" % (speed * 100))
		else:
			changed.emit(SPEED_PRESET_LABELS[speed_preset])


@export_storage var _manual_speed: float = speed

var initial_speed: float


func _ready() -> void:
	super()
	await require([EasingComponent])
	set_deferred(&"speed", speed) # initialize the label
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name == "speed" and speed_preset != SpeedPreset.MANUAL:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func start(player: Player) -> void:
	initial_speed = player.speed_multiplier


func _on_easing_progressed(player: Player, weight_delta: float) -> void:
	player.speed_multiplier += (speed - initial_speed) * weight_delta
	player.speed_multiplier = maxf(player.speed_multiplier, 0.01)
