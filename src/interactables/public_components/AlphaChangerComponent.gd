class_name AlphaChangerComponent
extends Component

enum Mode {
	SET,
	MULTIPLY,
	COPY,
}

@export var mode: Mode = Mode.SET:
	set(value):
		mode = value
		notify_property_list_changed()
@export_range(0.0, 1.0, 0.01, "slider") var alpha: float = 1.0
@export var copy_target: NodePath
@export_range(0.0, 1.0, 0.01, "or_greater") var copy_multiplier: float

@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var initial_alphas: Dictionary[HSVWatcher, float]
@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var group_hsv_watchers: Array[HSVWatcher]
@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var copy_target_hsv_watcher: HSVWatcher


func _ready() -> void:
	await require([TargetGroupComponent, EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name == "alpha" and mode == Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["copy_target", "copy_multiplier"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func _field_to_data(field_name: String) -> Variant:
	match field_name:
		"initial_alphas":
			var _initial_alphas: Dictionary[NodePath, float] = { }
			for hsv_watcher: HSVWatcher in initial_alphas:
				_initial_alphas[Serialize.Node(hsv_watcher)] = initial_alphas[hsv_watcher]
			return _initial_alphas
		"group_hsv_watchers":
			return group_hsv_watchers.map(Serialize.Node)
		"copy_target_hsv_watcher":
			return Serialize.Node(copy_target_hsv_watcher)
		_:
			return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	match field_name:
		"initial_alphas":
			for path: NodePath in field_data:
				initial_alphas[Deserialize.Node(path) as HSVWatcher] = field_data[path]
		"group_hsv_watchers":
			group_hsv_watchers.assign(field_data.map(Deserialize.Node))
		"copy_target_hsv_watcher":
			copy_target_hsv_watcher = Deserialize.Node(field_data)
		_:
			set(field_name, field_data)


func start(_player: Player) -> void:
	group_hsv_watchers.assign(
		get_tree() \
		.get_nodes_in_group(parent.query(TargetGroupComponent).target_group) \
		.filter(func(object): return object is Node2D) \
		.map(BaseDetailHandler.use_hsv_watcher),
	)
	group_hsv_watchers.map(func(hsv_watcher: HSVWatcher): initial_alphas.set(hsv_watcher, hsv_watcher.alpha))
	if group_hsv_watchers.is_empty():
		Toasts.warning("In %s: target group doesn't contain any objects" % parent.name)
	if mode == Mode.COPY and copy_target == null and Editor.in_editor:
		Toasts.error("In %s: copy target is unset" % parent.name)
		if not copy_target.is_empty():
			var copy_target_ref: Node = LevelManager.current_level.get_node_or_null(copy_target)
			if not copy_target_ref:
				Toasts.error("In %s: invalid copy target" % parent.name)
				return
			copy_target_hsv_watcher = BaseDetailHandler.use_hsv_watcher(copy_target_ref)


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	for hsv_watcher: HSVWatcher in group_hsv_watchers:
		var initial_alpha: float = initial_alphas[hsv_watcher]
		match mode:
			Mode.SET:
				hsv_watcher.alpha += (alpha - initial_alpha) * weight_delta
			Mode.MULTIPLY:
				hsv_watcher.alpha += (alpha * initial_alpha - initial_alpha) * weight_delta
			Mode.COPY:
				if copy_target_hsv_watcher:
					hsv_watcher.alpha += (copy_target_hsv_watcher.alpha * copy_multiplier - initial_alpha) * weight_delta
		hsv_watcher.update_color()
