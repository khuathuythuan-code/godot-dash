extends Component
class_name PositionChangerComponent

const CELLS_TO_PX := Vector2(LevelManager.CELL_SIZE, -LevelManager.CELL_SIZE)

enum Mode {
	ADD,
	SET,
	MOVE_TOWARDS,
}

@export var mode: Mode = Mode.ADD:
	set(value):
		mode = value
		notify_property_list_changed()
@export_custom(PROPERTY_HINT_NONE, "suffix:cells") var position: Vector2
@export var move_towards: Node2D
@export var group_center: Node2D
## Multiplies the target distance between each object in the group. [br][br]
## [b]Examples:[/b] [br]
##   •  [code]0.0[/code]: the group's objects will all move towards the target object. [br]
##   •  [code]1.0[/code]: the group's objects will follow the target object but [b]keep[/b] their relative distance to it. [br]
##   •  [code]2.0[/code]: the group's objects will follow the target object but [b]double[/b] their relative distance to it. [br]
##   •  [code]-1.0[/code]: the group's objects will follow the target object but [b]invert[/b] their relative distance to it.
@export_range(0.0, 2.0, 0.05, "or_greater", "or_less") var distance_multiplier: float = 1.0
@export var offset: Vector2 ## Offset in global coordinates in units from the move target.

var initial_global_positions: Dictionary[Node2D, Vector2]
var initial_distances: Dictionary[Node2D, Vector2]


func _ready() -> void:
	super()
	await require([TargetGroupComponent, EasingComponent])
	parent.interacted.connect(start)


func _validate_property(property: Dictionary) -> void:
	if property.name in ["move_towards", "group_center", "offset", "distance_multiplier"] and mode != Mode.MOVE_TOWARDS:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "position" and mode == Mode.MOVE_TOWARDS:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func start(_player: Player) -> void:
	var group_objects: Array[Node2D]
	group_objects.assign(get_tree() \
			.get_nodes_in_group(parent.query(TargetGroupComponent).target_group) \
			.filter(func(object): return object is Node2D))
	group_objects.map(func(object): initial_global_positions.set(object, object.global_position))
	if group_objects.is_empty():
		Toasts.warning("In %s: target group doesn't contain any objects" % parent.name)
	if mode == Mode.MOVE_TOWARDS:
		if move_towards:
			group_objects.map(func(object): initial_distances.set(object, move_towards.global_position - object.global_position))
		elif Editor.in_editor:
			Toasts.error("In %s: move towards is unset" % parent.name)
	
	var progressed: Signal = parent.query(EasingComponent).progressed
	if progressed.is_connected(_on_easing_progressed):
		progressed.disconnect(_on_easing_progressed)
	
	var process_objects: Array[Node2D]
	var physics_objects: Array[Node2D]
	for object in group_objects:
		var hitbox: CollisionObject2D = object as CollisionObject2D
		if hitbox == null or hitbox.is_shape_owner_disabled(hitbox.get_shape_owners()[0]) or object.process_mode == Node.PROCESS_MODE_DISABLED or (object is Area2D and object.monitoring == false):
			process_objects.append(object)
			continue
		physics_objects.append(object)
	
	if not process_objects.is_empty():
		progressed.connect(_on_easing_progressed.bind(process_objects))
	if not physics_objects.is_empty():
		progressed.connect(_on_easing_progressed.bind(physics_objects))


func _on_easing_progressed(_player: Player, weight_delta: float, group_objects: Array[Node2D]) -> void:
	match mode:
		Mode.ADD:
			for group_object in group_objects:
				group_object.global_position += position * CELLS_TO_PX * weight_delta
		Mode.SET:
			for group_object in group_objects:
				var initial_global_position = initial_global_positions[group_object]
				group_object.global_position += (parent.to_global(position * CELLS_TO_PX) - initial_global_position) * weight_delta
		Mode.MOVE_TOWARDS when move_towards != null:
			for group_object in group_objects:
				var initial_global_position = initial_global_positions[group_object]
				var initial_distance := initial_distances[group_object]
				# FIXME: doesn't work when `move_towards` is moving
				group_object.global_position += (move_towards.global_position - initial_global_position
						+ initial_distance * -distance_multiplier
						+ offset * CELLS_TO_PX) * weight_delta


