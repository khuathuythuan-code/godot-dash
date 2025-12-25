extends Component

class_name EasingComponent

signal progressed(weight_delta: float)
signal finished(player: Player)

@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var duration: float = 1.0
@export var easing_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var easing_transition: Tween.TransitionType
@export_group("Activation")
@export var keep_active: bool ## Keep the easing active after it completes.
@export var trigger_for_one_player: bool = true
@export var ignore_time_scale: bool = false
@export var _use_physics_process: bool = false

var tweens: Dictionary[Player, Tween]
var weights: Dictionary[Player, float]
var _previous_weights: Dictionary[Player, float]


func _ready() -> void:
	super()
	parent.interacted.connect(start)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for player in tweens.keys():
		if not is_inactive(player):
			progressed.emit(player, get_weight_delta(player))


func _validate_property(property: Dictionary) -> void:
	if property.name in ["trigger_for_one_player", "ignore_time_scale"] and parent.has(TimescaleChangerComponent):
		property.usage |= PROPERTY_USAGE_READ_ONLY
		trigger_for_one_player = true
		ignore_time_scale = true


func start(player: Player) -> void:
	if trigger_for_one_player and tweens.size() == 1:
		return
	tweens.set(player, create_tween())
	reset(player)
	var tween_weight := func(value: float): weights[player] = value
	tweens[player].set_process_mode(Tween.TWEEN_PROCESS_PHYSICS if _use_physics_process else Tween.TWEEN_PROCESS_IDLE)
	tweens[player].set_ignore_time_scale(ignore_time_scale)
	(
		tweens[player] \
		.tween_method(tween_weight, 0.0, 1.0, duration) \
		.set_trans(easing_transition) \
		.set_ease(easing_type)
	)
	tweens[player].finished.connect(
		func():
			finished.emit(player)
			if get_tree() != null:
				await get_tree().process_frame
			if get_tree() != null:
				await get_tree().process_frame
			tweens.erase(player)
	)


func get_weight_delta(player: Player) -> float:
	var result = weights[player] - _previous_weights[player]
	_previous_weights[player] = weights[player]
	return result


func is_inactive(player: Player) -> bool:
	return weights[player] == 0.0 or (_previous_weights[player] == 1.0 and not keep_active)


func is_inactive_any() -> bool:
	return weights.values().all(func(value): return value == 0.0) or (_previous_weights.values().all(func(value): return value == 1.0) and not keep_active)


func reset(player: Player) -> void:
	weights[player] = 0.0
	_previous_weights[player] = 0.0
