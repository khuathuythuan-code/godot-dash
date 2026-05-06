class_name CameraGameplayOffsetChangerComponent
extends Component

enum Mode {
	SET,
	ADD,
}

@export var mode: Mode = Mode.SET
@export_custom(PROPERTY_HINT_RANGE, "-100.0,100.0,0.01,or_greater,or_less,suffix:%") var gameplay_offset := Vector2.ONE * 100.0

@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var initial_gameplay_offset_factor: Vector2


func _ready() -> void:
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _field_to_data(field_name: String) -> Variant:
	match field_name:
		"gameplay_offset":
			return Serialize.Vector2(gameplay_offset)
		_:
			return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	match field_name:
		"gameplay_offset":
			gameplay_offset = Deserialize.Vector2(field_data)
		_:
			set(field_name, field_data)


func start(_player: Player) -> void:
	initial_gameplay_offset_factor = LevelManager.player_camera.gameplay_offset_factor


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	match mode:
		Mode.ADD:
			LevelManager.player_camera.gameplay_offset_factor += gameplay_offset * 0.01 * weight_delta
		Mode.SET:
			LevelManager.player_camera.gameplay_offset_factor += (gameplay_offset * 0.01 - initial_gameplay_offset_factor) * weight_delta
