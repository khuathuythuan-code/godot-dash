extends Component

class_name CameraGameplayOffsetChangerComponent

enum Mode {
	SET,
	ADD,
}

@export var mode: Mode = Mode.SET
@export_custom(PROPERTY_HINT_RANGE, "-100.0,100.0,0.01,or_greater,or_less,suffix:%") var gameplay_offset := Vector2.ONE * 100.0

var initial_gameplay_offset_factor: Vector2


func _ready() -> void:
	super()
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func start(_player: Player) -> void:
	initial_gameplay_offset_factor = LevelManager.player_camera.gameplay_offset_factor


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	match mode:
		Mode.ADD:
			LevelManager.player_camera.gameplay_offset_factor += gameplay_offset * 0.01 * weight_delta
		Mode.SET:
			LevelManager.player_camera.gameplay_offset_factor += (gameplay_offset * 0.01 - initial_gameplay_offset_factor) * weight_delta
