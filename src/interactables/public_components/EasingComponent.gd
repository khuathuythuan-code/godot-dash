class_name EasingComponent
extends Component

signal progressed(player: Player, weight_delta: float)
signal finished(player: Player)
signal restored(player: Player)

@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var duration: float = 1.0
@export var easing_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var easing_transition: Tween.TransitionType
@export_custom(PROPERTY_HINT_TOOL_BUTTON, "Preview,Play") var preview: Callable = start_preview

@export_group("Activation")
@export var keep_active: bool ## Keep the easing active after it completes.
@export var trigger_for_one_player: bool = true
@export var ignore_time_scale: bool = false
@export var _use_physics_process: bool = false

@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var elapsed_time: Dictionary[NodePath, float]

var is_previewing: bool = false
var tweens: Dictionary[Player, Tween]
var weights: Dictionary[Player, float]
var _previous_weights: Dictionary[Player, float]


func _ready() -> void:
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
	elif property.name == "preview" and is_previewing:
		property.hint_string = "Preview,Stop"


func _field_to_data(field_name: String) -> Variant:
	if is_previewing:
		stop_preview(LevelManager.player)
	match field_name:
		"elapsed_time":
			return get_elapsed_time()
		"preview":
			return null
		_:
			return get(field_name)


func _field_from_data(field_name: String, field_data: Variant) -> void:
	match field_name:
		"elapsed_time":
			elapsed_time = field_data
			restore_from_elapsed_time.call_deferred()
		_:
			set(field_name, field_data)


func start(player: Player) -> void:
	if LevelManager.level_playing and is_previewing:
		stop_preview(player)
	if trigger_for_one_player and tweens.size() == 1:
		return
	tweens[player] = create_tween()
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


func start_preview() -> void:
	var player: Player = LevelManager.player
	if is_previewing:
		stop_preview(player)
		return
	is_previewing = true
	notify_property_list_changed()
	finished.connect(_on_preview_end, CONNECT_ONE_SHOT)
	parent.interacted.emit(player)


func stop_preview(player: Player) -> void:
	is_previewing = false
	if player in tweens:
		_on_preview_end(player)
		tweens[player].kill()
		tweens.erase(player)


func get_elapsed_time() -> Dictionary[NodePath, float]:
	var _elapsed_time: Dictionary[NodePath, float] = { }
	for player in tweens:
		_elapsed_time[Serialize.Node(player)] = tweens[player].get_total_elapsed_time()
	return _elapsed_time


func restore_from_elapsed_time() -> void:
	for player_path: NodePath in elapsed_time:
		var player: Player = Deserialize.Node(player_path)
		start(player)
		restored.emit(player)
		tweens[player].custom_step(elapsed_time[player_path])


func _on_preview_end(player: Player) -> void:
	var reverse_weight: float = -weights[player]
	reset(player)
	progressed.emit(player, reverse_weight)
	is_previewing = false
	notify_property_list_changed()
