@tool
extends Node2D
class_name ReboundPadSprite

var factor: float:
	set(value):
		factor = value
		camera_rect = LevelManager.current_level.camera_rect
		var new_factor_smoothed: float = lerpf(_factor_smoothed, factor, 1-exp(-get_physics_process_delta_time() * 20))
		if not (camera_rect.position.x < global_position.x and camera_rect.end.x > global_position.x):
			_factor_smoothed = new_factor_smoothed
			return
		if visible and new_factor_smoothed != _factor_smoothed:
			_factor_smoothed = new_factor_smoothed # can't add arguments to _draw
			queue_redraw()

var _factor_smoothed: float
var camera_rect: Rect2
@onready var _rebound_gradient: Gradient = preload("res://resources/gradients/rebound_gradient.tres")

func _ready() -> void:
	$"../../ReboundComponent".sprite = self

func _draw() -> void:
	var inner_radius := lerpf(74.4, 55.8, _factor_smoothed)
	var color := _rebound_gradient.sample(_factor_smoothed)
	var draw_height := lerpf(60, 30, factor)
	var draw_position := Vector2(0, draw_height)
	# Exterior arc
	draw_circle(draw_position, inner_radius, Color.WHITE, false, 4, true)
	# Interior arc
	draw_circle(draw_position, inner_radius-2, color, true, -1.0, true)
	# Set particle emitter color
	$"../../ParticleEmitter".modulate = color
