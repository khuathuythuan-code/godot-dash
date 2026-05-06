class_name CameraShakeComponent
extends Component

enum Axis {
	BOTH,
	ANGLE,
}

enum Eased {
	STRENGTH, ## Multiplies the strength by the easing weight
	SPEED_AND_STRENGTH,
}

@export var axis: Axis:
	set(value):
		axis = value
		notify_property_list_changed()
@export_range(-180, 180, 0.01, "degrees", "slider") var angle: float
@export var eased: Eased
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:%") var strength: float = 10.0
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:%") var speed: float = 100.0

var noise: FastNoiseLite
var linear_eased_weight: float


func _ready() -> void:
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)
	noise = FastNoiseLite.new()
	# RIDs will change every time the resource is created
	noise.seed = hash(noise)


func _validate_property(property: Dictionary) -> void:
	if property.name == "angle" and axis != Axis.ANGLE:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func start(_player: Player):
	linear_eased_weight = 0.0


func _on_easing_progressed(player: Player, _weight_delta: float) -> void:
	var weight: float = parent.query(EasingComponent).weights[player]
	linear_eased_weight += get_process_delta_time() / parent.query(EasingComponent).duration
	var noise_sample_position := weight * speed / 100 if eased == Eased.SPEED_AND_STRENGTH else linear_eased_weight * speed / 100
	noise_sample_position *= 10000
	var sample_strength := 1 - weight if eased == Eased.STRENGTH or eased == Eased.SPEED_AND_STRENGTH else 1.0
	match axis:
		Axis.BOTH:
			LevelManager.player_camera.shake_offset.x = noise.get_noise_2d(
				noise_sample_position,
				0.0,
			) * sample_strength * strength * 10.0
			LevelManager.player_camera.shake_offset.y = noise.get_noise_2d(
				1.0, # Offset so the starting value is different
				noise_sample_position,
			) * sample_strength * strength * 10.0
		Axis.ANGLE:
			LevelManager.player_camera.shake_offset = Vector2.from_angle(deg_to_rad(angle)) * noise.get_noise_1d(
				noise_sample_position,
			) * sample_strength * strength * 10.0
