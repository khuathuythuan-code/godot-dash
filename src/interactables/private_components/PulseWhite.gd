class_name PulseWhite
extends Node

@export var pulse_target: Node2D
@onready var parent := get_parent() as Interactable
var _factor: float


func _ready() -> void:
	parent.interacted.connect(pulse)
	if pulse_target and pulse_target.material:
		pulse_target.material = pulse_target.material.duplicate()
	for child in pulse_target.get_children():
		if child is Node2D and child.material:
			child.material = child.material.duplicate()


func _process(delta: float) -> void:
	if is_zero_approx(_factor):
		return
	_factor = move_toward(_factor, 0.0, delta * 6)
	if pulse_target and pulse_target.material:
		pulse_target.material.set_shader_parameter(&"factor", _factor)
	for child in pulse_target.get_children():
		if child is Node2D and child.material:
			child.material.set_shader_parameter(&"factor", _factor)


func pulse(_player: Player) -> void:
	if parent.has(NoEffectsComponent):
		return
	_factor = 1.0
