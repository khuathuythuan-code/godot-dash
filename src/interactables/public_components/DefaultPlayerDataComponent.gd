extends Component

class_name DefaultPlayerDataComponent

enum Speed {
	x0,
	x05,
	x1,
	x2,
	x3,
	x4,
	x5,
}

@export var platformer: bool:
	set(value):
		platformer = value
		notify_property_list_changed()
@export var reverse: bool
@export_enum("x0.0", "x0.5", "x1.0", "x2.0", "x3.0", "x4.0", "x5.0") var speed: int = Speed.x1
@export_range(-180, 180, 0.01, "degrees", "slider") var gameplay_rotation: float

@export_group("Gamemode")
@export var internal: Player.Gamemode
@export var displayed: Player.Gamemode
@export var freefly: bool


func _validate_property(property: Dictionary) -> void:
	if property.name == "reverse" and platformer:
		property.usage |= PROPERTY_USAGE_READ_ONLY


func get_speed():
	return Level.START_SPEED[speed]
