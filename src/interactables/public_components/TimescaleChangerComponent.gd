extends Component
class_name TimescaleChangerComponent

signal changed(time_scale: String)

@export var time_scale: float = 1.0:
	set(value):
		time_scale = value
		changed.emit("%.f%%" % (time_scale * 100))

var initial_time_scale: float

func _ready() -> void:
	super()
	await require([EasingComponent])
	changed.emit("%.f%%" % (time_scale * 100))
	parent.interacted.connect(start)
	parent.query(EasingComponent).progressed.connect(_on_easing_progressed)


func start(_player: Player) -> void:
	initial_time_scale = Engine.time_scale


func _on_easing_progressed(_player: Player, weight_delta: float) -> void:
	Engine.time_scale += (time_scale - initial_time_scale) * weight_delta
