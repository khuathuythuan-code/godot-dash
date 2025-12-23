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
		if Editor.in_editor:
			Editor.root.level.platformer = value
		notify_property_list_changed()
@export var reverse: bool:
	set(value):
		reverse = value
		if Editor.in_editor:
			Editor.root.level.start_reverse = value
@export_enum("x0.0", "x0.5", "x1.0", "x2.0", "x3.0", "x4.0", "x5.0") var speed: int = Speed.x1:
	set(value):
		speed = value
		if Editor.in_editor:
			Editor.root.level.start_speed = value
@export_range(-180, 180, 0.01, "degrees", "slider") var gameplay_rotation: float:
	set(value):
		gameplay_rotation = value
		if Editor.in_editor:
			Editor.root.level.start_gameplay_rotation_degrees = value

@export_group("Gamemode")
@export var internal: Player.Gamemode:
	set(value):
		internal = value
		if Editor.in_editor:
			Editor.root.level.start_internal_gamemode = value
@export var displayed: Player.Gamemode:
	set(value):
		displayed = value
		if Editor.in_editor:
			Editor.root.level.start_displayed_gamemode = value
@export var freefly: bool = true:
	set(value):
		freefly = value
		if Editor.in_editor:
			Editor.root.level.start_freefly = value


func _validate_property(property: Dictionary) -> void:
	if property.name == "reverse" and platformer:
		property.usage |= PROPERTY_USAGE_READ_ONLY


func get_speed():
	return Level.START_SPEED[speed]
