class_name ScaleChangerComponent
extends Component

enum Mode {
	MULTIPLY,
	ADD,
	SET,
}

@export var mode: Mode = Mode.MULTIPLY:
	set(value):
		mode = value
		notify_property_list_changed()
@export var scale: Vector2
@export var pivot: NodePath
@export var scale_around_self: bool:
	set(value):
		scale_around_self = value
		notify_property_list_changed()
@export var change_position_only: bool

var initial_global_scales: Dictionary[Node2D, Vector2]
var group_objects: Array[Node2D]


func _ready() -> void:
	await require([TargetGroupComponent, EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name == "pivot" and scale_around_self:
		property.usage |= PROPERTY_USAGE_READ_ONLY


func start(_player: Player) -> void:
	group_objects.assign(
		get_tree() \
		.get_nodes_in_group(parent.query(TargetGroupComponent).target_group) \
		.filter(func(object): return object is Node2D),
	)
	group_objects.map(func(object): initial_global_scales.set(object, object.global_scale))
	if group_objects.is_empty():
		Toasts.warning("In %s: target group doesn't contain any objects" % parent.name)


func _field_to_data(field_name: String) -> Variant:
	match field_name:
		"scale":
			return Serialize.Vector2(scale)
		_:
			return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	match field_name:
		"scale":
			scale = Deserialize.Vector2(field_data)
		_:
			set(field_name, field_data)


func _apply_scale_delta(group_object: Node2D, scale_delta: Vector2) -> void:
	if scale_around_self:
		group_object.global_scale += scale_delta
	else:
		var pivot_ref: Node2D = LevelManager.current_level.get_node(pivot)
		var position_relative_to_pivot: Vector2 = group_object.global_position - pivot_ref.global_position
		var position_delta := position_relative_to_pivot * ((group_object.global_scale + scale_delta) / group_object.global_scale) - position_relative_to_pivot
		group_object.global_position += position_delta
		if not change_position_only:
			group_object.global_scale += scale_delta


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	for group_object in group_objects:
		var initial_global_scale := initial_global_scales[group_object]
		var scale_delta: Vector2
		match mode:
			Mode.SET:
				scale_delta = (scale - initial_global_scale) * weight_delta
			Mode.ADD:
				scale_delta = scale * weight_delta
			Mode.MULTIPLY:
				scale_delta = (initial_global_scale * scale - initial_global_scale) * weight_delta
		_apply_scale_delta(group_object, scale_delta)
		if group_object is StaticBody2D:
			var absolutesize: NinePatchSprite2DAbsoluteSize = group_object.get_node_or_null(^"NinePatchSprite2DAbsoluteSize")
			if absolutesize == null:
				return
			absolutesize.update_size()

