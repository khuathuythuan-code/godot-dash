class_name CameraOffsetChangerComponent
extends Component

enum Mode {
	ADD,
	SET,
}

@export var mode: Mode = Mode.ADD
@export_custom(PROPERTY_HINT_NONE, "suffix:cells") var offset := Vector2.ZERO

@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var initial_offset: Vector2
@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var initial_gameplay_offset: Vector2


func _ready() -> void:
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _field_to_data(field_name: String) -> Variant:
	match field_name:
		"offset":
			return Serialize.Vector2(offset)
		_:
			return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	match field_name:
		"offset":
			offset = Deserialize.Vector2(field_data)
		_:
			set(field_name, field_data)


func start(_player: Player) -> void:
	initial_offset = LevelManager.player_camera.additional_offset


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	match mode:
		Mode.ADD:
			LevelManager.player_camera.additional_offset += offset * Constants.CELLS_TO_PX * weight_delta
		Mode.SET:
			LevelManager.player_camera.additional_offset += (offset * Constants.CELLS_TO_PX - initial_offset) * weight_delta
