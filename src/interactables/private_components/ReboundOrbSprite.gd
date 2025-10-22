@tool
extends Node2D
class_name ReboundOrbSprite

@onready var _rebound_gradient: Gradient = preload("res://resources/gradients/rebound_gradient.tres")

var factor: float:
	set(value):
		factor = value
		var new_factor_smoothed: float = lerpf(_factor_smoothed, factor, 1-exp(-get_physics_process_delta_time() * 20))
		if visible and new_factor_smoothed != _factor_smoothed:
			_factor_smoothed = new_factor_smoothed
			queue_redraw()

var _factor_smoothed: float

func _ready() -> void:
	if has_node("../ReboundComponent"):
		$"../ReboundComponent".sprite = self

func _draw() -> void:
	var inner_radius := lerpf(32, 52, _factor_smoothed)
	var color := _rebound_gradient.sample(_factor_smoothed)
	# Exterior ring
	draw_circle(Vector2.ZERO, 61, Color.WHITE, false, 6)
	# Interior ring
	draw_circle(Vector2.ZERO, inner_radius-3, Color.WHITE, false, 6)
	# Interior circle
	draw_circle(Vector2.ZERO, inner_radius-6, color, true)
	# Set particle emitter color
	if has_node("../ParticleEmitter"):
		$"../ParticleEmitter".modulate = color
