extends Component

class_name AlphaChangerComponent

enum Mode {
	SET,
	MULTIPLY,
	DIVIDE,
	COPY,
}

@export var mode: Mode = Mode.SET:
	set(value):
		mode = value
		notify_property_list_changed()
@export_range(0.0, 1.0, 0.01, "slider") var alpha: float = 1.0
@export var copy_target: Node2D
@export_range(0.0, 1.0, 0.01, "or_greater") var copy_multiplier: float

var initial_alphas: Dictionary[HSVWatcher, float]
var group_hsv_watchers: Array[HSVWatcher]
var copy_target_hsv_watcher: HSVWatcher


func _ready() -> void:
	super()
	await require([TargetGroupComponent, EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name == "alpha" and mode == Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["copy_target", "copy_multiplier"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR


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
	if copy_target:
		copy_target_hsv_watcher = BaseDetailHandler.use_hsv_watcher(copy_target)


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	for hsv_watcher: HSVWatcher in group_hsv_watchers:
		var initial_alpha := initial_alphas[hsv_watcher]
		match mode:
			Mode.SET:
				hsv_watcher.alpha += (alpha - initial_alpha) * weight_delta
			Mode.MULTIPLY:
				hsv_watcher.alpha += (alpha * initial_alpha - initial_alpha) * weight_delta
			Mode.COPY:
				if copy_target_hsv_watcher:
					hsv_watcher.alpha += (copy_target_hsv_watcher.alpha * copy_multiplier - initial_alpha) * weight_delta
		hsv_watcher.update_color()
