class_name PulseWhite
extends Node

@export var pulse_target: Node2D
@onready var parent := get_parent() as Interactable
var _factor: float


func _ready() -> void:
	parent.interacted.connect(pulse)


func _process(delta: float) -> void:
	if is_zero_approx(_factor):
		return
	_factor = move_toward(_factor, 0.0, delta * 6)
	pulse_target.set_instance_shader_parameter(&"factor", _factor)
	if pulse_target.get_child_count() > 0:
		for child: Node2D in pulse_target.get_children():
			child.set_instance_shader_parameter(&"factor", _factor)


func pulse(_player: Player) -> void:
	if parent.has(NoEffectsComponent):
		return
	_factor = 1.0
