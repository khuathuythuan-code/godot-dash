extends Component

class_name CameraOffsetChangerComponent

enum Mode {
	ADD,
	SET,
}

@export var mode: Mode = Mode.ADD
@export_custom(PROPERTY_HINT_NONE, "suffix:cells") var offset := Vector2.ZERO

var initial_offset: Vector2
var initial_gameplay_offset: Vector2


func _ready() -> void:
	super()
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func start(_player: Player) -> void:
	initial_offset = LevelManager.player_camera.additional_offset


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	match mode:
		Mode.ADD:
			LevelManager.player_camera.additional_offset += offset * Constants.CELLS_TO_PX * weight_delta
		Mode.SET:
			LevelManager.player_camera.additional_offset += (offset * Constants.CELLS_TO_PX - initial_offset) * weight_delta
