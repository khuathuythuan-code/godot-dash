class_name PositionChangerComponent
extends Component

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
@export var move_towards: NodePath
## Multiplies the target distance between each object in the group. [br][br]
## [b]Examples:[/b] [br]
##   •  [code]0.0[/code]: the group's objects will all move towards the target object. [br]
##   •  [code]1.0[/code]: the group's objects will follow the target object but [b]keep[/b] their relative distance to it. [br]
##   •  [code]2.0[/code]: the group's objects will follow the target object but [b]double[/b] their relative distance to it. [br]
##   •  [code]-1.0[/code]: the group's objects will follow the target object but [b]invert[/b] their relative distance to it.
@export_range(0.0, 2.0, 0.05, "or_greater", "or_less", "slider") var distance_multiplier: float = 0.0
@export var offset: Vector2 ## Offset in global coordinates in units from the move target.

var initial_global_positions: Dictionary[Node2D, Vector2]
var initial_distances: Dictionary[Node2D, Vector2]
var group_objects: Array[Node2D]


func _ready() -> void:
	await require([TargetGroupComponent, EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name in ["move_towards", "group_center", "offset", "distance_multiplier"] and mode != Mode.MOVE_TOWARDS:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "position" and mode == Mode.MOVE_TOWARDS:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func _field_to_data(field_name: String) -> Variant:
	match field_name:
		"position":
			return Serialize.Vector2(position)
		"offset":
			return Serialize.Vector2(offset)
		_:
			return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	match field_name:
		"position":
			position = Deserialize.Vector2(field_data)
		"offset":
			offset = Deserialize.Vector2(field_data)
		_:
			set(field_name, field_data)


func start(_player: Player) -> void:
	group_objects.assign(
		get_tree() \
		.get_nodes_in_group(parent.query(TargetGroupComponent).target_group) \
		.filter(func(object): return object is Node2D),
	)
	group_objects.map(func(object): initial_global_positions.set(object, object.global_position))
	if group_objects.is_empty():
		Toasts.warning("In %s: target group doesn't contain any objects" % parent.name)
	if mode == Mode.MOVE_TOWARDS:
		if move_towards != ^"":
			var move_towards_ref: Node2D = LevelManager.current_level.get_node(move_towards)
			group_objects.map(func(object): initial_distances.set(object, move_towards_ref.global_position - object.global_position))
		elif Editor.in_editor:
			Toasts.error("In %s: move towards is unset" % parent.name)


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	match mode:
		Mode.ADD:
			for group_object in group_objects:
				group_object.global_position += position * Constants.CELLS_TO_PX * weight_delta
		Mode.SET:
			for group_object in group_objects:
				var initial_global_position = initial_global_positions[group_object]
				group_object.global_position += (parent.to_global(position * Constants.CELLS_TO_PX) - initial_global_position) * weight_delta
		Mode.MOVE_TOWARDS when move_towards != ^"":
			for group_object in group_objects:
				var initial_global_position = initial_global_positions[group_object]
				var initial_distance := initial_distances[group_object]
				# FIXME: doesn't work when `move_towards` is moving
				var move_towards_ref: Node2D = LevelManager.current_level.get_node(move_towards)
				group_object.global_position += (
					move_towards_ref.global_position - initial_global_position
					+ initial_distance * -distance_multiplier
					+ offset * Constants.CELLS_TO_PX
				) * weight_delta
