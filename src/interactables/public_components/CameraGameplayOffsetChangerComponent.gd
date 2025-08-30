extends Component
class_name CameraGameplayOffsetChangerComponent

enum Mode {
	SET,
	ADD,
}

@export var mode: Mode = Mode.SET
@export_custom(PROPERTY_HINT_RANGE, "0.0,1.0,0.01,suffix:%") var gameplay_offset := Vector2.ONE

var initial_gameplay_offset: Vector2

func _ready() -> void:
	super()
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func start(_player: Player) -> void:
	initial_gameplay_offset = LevelManager.player_camera.gameplay_offset


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	match mode:
		Mode.ADD:
			LevelManager.player_camera.gameplay_offset += gameplay_offset * weight_delta
		Mode.SET:
			LevelManager.player_camera.gameplay_offset += (gameplay_offset - initial_gameplay_offset) * weight_delta


