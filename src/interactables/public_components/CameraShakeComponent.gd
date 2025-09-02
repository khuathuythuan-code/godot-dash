extends Component
class_name CameraShakeComponent

enum Axis {
	BOTH,
	X,
	Y,
}

enum Eased {
	STRENGTH, ## Multiplies the strength by the easing weight
	SPEED_AND_STRENGTH,
}

@export var axis: Axis
@export var eased: Eased
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:%") var speed: float = 100.0
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:%") var strength: float = 100.0

var noise: FastNoiseLite
var linear_eased_weight: float


func _ready() -> void:
	super()
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)
	noise = FastNoiseLite.new()
	# RIDs will change every time the resource is created
	noise.seed = hash(noise)


func start(_player: Player):
	linear_eased_weight = 0.0



func _on_easing_progressed(player: Player, _weight_delta: float) -> void:
	var weight: float = parent.query(EasingComponent).weights[player]
	linear_eased_weight += get_process_delta_time() / parent.query(EasingComponent).duration
	var noise_sample_position := weight * speed/100 if eased == Eased.SPEED_AND_STRENGTH else linear_eased_weight * speed/100
	noise_sample_position *= 10000
	var sample_strength := 1 - weight if eased == Eased.STRENGTH or eased == Eased.SPEED_AND_STRENGTH else 1.0
	if axis == Axis.X or axis == Axis.BOTH:
		LevelManager.player_camera.shake_offset.x = noise.get_noise_2d(
			noise_sample_position,
			0.0
		) * sample_strength * strength * 10.0
		print(LevelManager.player_camera.shake_offset.x)
	if axis == Axis.Y or axis == Axis.BOTH:
		LevelManager.player_camera.shake_offset.y = noise.get_noise_2d(
			1.0, # Offset so the starting value is different
			noise_sample_position
		) * sample_strength * strength * 10.0

