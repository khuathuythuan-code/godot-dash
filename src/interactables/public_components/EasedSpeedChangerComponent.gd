class_name EasedSpeedChangerComponent
extends Component

signal changed(speed: String)

enum SpeedPreset {
	x0,
	x05,
	x1,
	x2,
	x3,
	x4,
	x5,
	CUSTOM,
}

const SPEED_PRESET_LABELS: PackedStringArray = ["x0.0", "x0.5", "x1.0", "x2.0", "x3.0", "x4.0", "x5.0"]

@export_enum("x0.0", "x0.5", "x1.0", "x2.0", "x3.0", "x4.0", "x5.0", "Custom") var speed_preset: int = SpeedPreset.x1:
	set(value):
		speed_preset = value
		speed = Level.START_SPEED[speed_preset] if speed_preset != SpeedPreset.CUSTOM else _manual_speed
		notify_property_list_changed()

@export_range(0.0, 2.0, 0.01, "or_greater", "slider") var speed: float = 1.0:
	set(value):
		speed = value
		if speed_preset == SpeedPreset.CUSTOM:
			_manual_speed = value
			changed.emit("%.f%%" % (speed * 100))
		else:
			changed.emit(SPEED_PRESET_LABELS[speed_preset])

@export_storage var _manual_speed: float = speed

@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var initial_speed: float


func _ready() -> void:
	await require([EasingComponent])
	set_deferred(&"speed", speed) # initialize the label
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name == "speed" and speed_preset != SpeedPreset.CUSTOM:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func start(player: Player) -> void:
	initial_speed = player.speed_multiplier
	var duration: float = parent.query(EasingComponent).duration
	if player == LevelManager.player_camera.player:
		var center_on_player_at_0x_speed: bool = speed > 0.0 or (speed == 0.0 and duration == 0.0)
		LevelManager.player_camera.center_on_player_at_0x_speed = center_on_player_at_0x_speed
	if speed == 0.0 and duration == 0.0:
		player.speed_0_portal_control = parent


func _on_easing_progressed(player: Player, weight_delta: float) -> void:
	player.speed_multiplier += (speed - initial_speed) * weight_delta
