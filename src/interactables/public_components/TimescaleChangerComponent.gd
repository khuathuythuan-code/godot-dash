class_name TimescaleChangerComponent
extends Component

signal changed(time_scale: String)

@export_range(0.01, 2.0, 0.01, "or_greater") var time_scale: float = 1.0:
	set(value):
		time_scale = value
		changed.emit("%.f%%" % (time_scale * 100))

@export_custom(PROPERTY_HINT_NONE, "serialize:PRACTICE_ATTEMPT", PROPERTY_USAGE_STORAGE)
var initial_time_scale: float


func _ready() -> void:
	await require([EasingComponent])
	set_deferred(&"time_scale", time_scale) # initialize the label
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func start(_player: Player) -> void:
	initial_time_scale = Engine.time_scale


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	Engine.time_scale += (time_scale - initial_time_scale) * weight_delta
	Engine.time_scale = maxf(Engine.time_scale, 0.01)
