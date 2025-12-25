extends Component

class_name CameraZoomChangerComponent

enum Mode {
	SET,
	MULTIPLY,
	ADD,
}

@export var mode: Mode = Mode.SET
@export_custom(PROPERTY_HINT_RANGE, "0.0,100.0,0.01,or_greater,suffix:%") var zoom := Vector2.ONE * 100.0

var initial_zoom: Vector2


func _ready() -> void:
	super()
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func start(_player: Player) -> void:
	initial_zoom = LevelManager.player_camera.zoom


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	match mode:
		Mode.SET:
			LevelManager.player_camera.zoom += (zoom * PlayerCamera.DEFAULT_ZOOM * 0.01 - initial_zoom) * weight_delta
		Mode.ADD:
			LevelManager.player_camera.zoom += (zoom * PlayerCamera.DEFAULT_ZOOM * 0.01) * weight_delta
		Mode.MULTIPLY:
			LevelManager.player_camera.zoom += (initial_zoom * (zoom * PlayerCamera.DEFAULT_ZOOM * 0.01) - initial_zoom) * weight_delta
