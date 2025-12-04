extends Component
class_name SpawnTriggerComponent


enum LoopState {
	DISABLED,
	COUNT,
	INFINITE,
}

# TODO in editor, refresh timer duration if a spawned trigger's duration is changed
@export var spawned_triggers: Array[SpawnedTrigger]:
	set(value):
		if not is_node_ready():
			await ready
		spawned_triggers = value
		# spawned_triggers = value.filter(func(group):
		# 	var trigger := LevelManager.current_level.get_node_or_null(group.path)
		# 	return trigger != null and trigger is Interactable and trigger.has(TriggerHitboxComponent))
@export var loop: LoopState = LoopState.DISABLED:
	set(value):
		loop = value
		notify_property_list_changed()
@export var loop_count: int = 1
@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var loop_delay: float = 0.0

var _duration: float
var _current_loop: int = 1
var _elapsed_time: float


func _ready() -> void:
	super()
	await require([EasingComponent])
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func _validate_property(property: Dictionary) -> void:
	if property.name in ["loop_count", "loop_delay"] and loop == LoopState.DISABLED:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "loop_count" and loop == LoopState.INFINITE:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func start(player: Player) -> void:
	if spawned_triggers.is_empty():
		Toasts.warning("In %s: spawned triggers is empty" % parent.name)
		return
	var skip_deleted := func(trigger):
		var spawned_trigger = LevelManager.current_level.get_node_or_null(trigger.path)
		if spawned_trigger == null:
			return false
		return not spawned_trigger.is_in_group(Constants.DELETED_GROUP)
	spawned_triggers = spawned_triggers.filter(skip_deleted)
	for trigger in spawned_triggers:
		if trigger.time > _duration:
			_duration = trigger.time
	parent.query(EasingComponent).duration = _duration
	_elapsed_time = 0.0
	if loop != LoopState.DISABLED:
		if _duration > 0.0:
			NodeUtils.connect_once(parent.query(EasingComponent).finished, restart)
		else:
			restart(player)


func restart(player: Player) -> void:
	await get_tree().create_timer(loop_delay, false).timeout
	if loop == LoopState.INFINITE or (loop == LoopState.COUNT and _current_loop < loop_count):
		_current_loop += 1
		parent.interacted.emit(player)


func _field_to_data(field_name: String) -> Variant:
	if field_name == "spawned_triggers":
		return spawned_triggers.map(func(spawned_trigger: SpawnedTrigger): return spawned_trigger.to_data())
	return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	if field_name == "spawned_triggers":
		spawned_triggers.assign(field_data.map(func(spawned_trigger_data: Dictionary): SpawnedTrigger.from_data(spawned_trigger_data)))
		return
	set(field_name, field_data)


func _on_easing_progressed(player: Player, weight_delta: float) -> void:
	if spawned_triggers.is_empty():
		return
	_elapsed_time += _duration * weight_delta
	for trigger in spawned_triggers:
		print(trigger.loop_idx < _current_loop)
		if _elapsed_time >= trigger.time - get_process_delta_time() and trigger.loop_idx < _current_loop:
			var trigger_node := LevelManager.current_level.get_node(trigger.path)
			trigger_node.interacted.emit(player)
			trigger.loop_idx = _current_loop
