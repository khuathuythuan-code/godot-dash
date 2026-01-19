extends Node
class_name PulseWhite

var _factor: float
var _pulse_target: Node2D

@onready var parent := get_parent() as Interactable


func _ready() -> void:
	parent.interacted.connect(pulse)
	_pulse_target = get_node_or_null("../Sprites")
	if _pulse_target == null:
		_pulse_target = get_node_or_null("../Sprite")


func _process(delta: float) -> void:
	if _factor != 0.0:
		_factor = move_toward(_factor, 0.0, delta * 6)
		_pulse_target.material.set_shader_parameter("factor", _factor)
	else:
		_pulse_target.use_parent_material = true


func pulse(_player: Player) -> void:
	if parent.has(NoEffectsComponent):
		return
	_pulse_target.use_parent_material = false
	_factor = 1.0
