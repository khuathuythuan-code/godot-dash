class_name CameraZoomChangerComponent
extends Component

enum Mode {
	SET,
	MULTIPLY,
	ADD,
}

@export var mode: Mode = Mode.SET
@export_custom(PROPERTY_HINT_RANGE, "0.0,100.0,0.01,or_greater,suffix:%") var zoom := Vector2.ONE * 100.0

@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var initial_zoom: Vector2


func _ready() -> void:
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _field_to_data(field_name: String) -> Variant:
	match field_name:
		"zoom":
			return Serialize.Vector2(zoom)
		_:
			return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	match field_name:
		"zoom":
			zoom = Deserialize.Vector2(field_data)
		_:
			set(field_name, field_data)


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
