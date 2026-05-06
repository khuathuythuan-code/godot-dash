class_name CameraRotationChangerComponent
extends Component

enum Mode {
	ADD,
	SET,
}

@export var mode: Mode = Mode.ADD
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var rotation_degrees: float

var initial_global_rotation_degrees: float


func _ready() -> void:
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func start(_player: Player) -> void:
	initial_global_rotation_degrees = LevelManager.player_camera.rotation_degrees


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	match mode:
		Mode.SET:
			LevelManager.player_camera.rotation_degrees += (rotation_degrees - initial_global_rotation_degrees) * weight_delta
		Mode.ADD:
			LevelManager.player_camera.rotation_degrees += rotation_degrees * weight_delta
