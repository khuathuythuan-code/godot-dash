extends Camera2D

class_name PlayerCamera

const DEFAULT_ZOOM: Vector2 = Vector2(0.8, 0.8)
const DEFAULT_OFFSET: Vector2 = Vector2(400.0, 0.0)
const MAX_DISTANCE := Vector2(400.0, 300.0)

@export var ground_down: GroundObject
@export var ground_up: GroundObject

@export var position_smoothing: float = 0.1
@export var offset_smoothing: float = 0.125
@export var gameplay_offset := Vector2.ONE
@export var additional_offset: Vector2

var player: Player
var freefly := true


func _ready() -> void:
	LevelManager.player_camera = self
	player = LevelManager.player
	offset = get_offset_target()


func _physics_process(delta: float) -> void:
	if not LevelManager.level_playing:
		return
	queue_redraw()
	var framerate_compensation := delta * 60.0

	var player_distance = player.position - position
	var ground_distance = GroundData.center - position + Vector2.from_angle(player.gameplay_rotation - PI/2) * GroundData.offset
	# Rotation-local
	var local_player_distance = player_distance.rotated(-player.gameplay_rotation)
	var local_ground_distance = ground_distance.rotated(-player.gameplay_rotation)
	var local_added_distance = local_player_distance
	local_added_distance.y = local_target_distance_axis(
		local_player_distance.y if freefly else local_ground_distance.y,
		MAX_DISTANCE.y / zoom.y,
		framerate_compensation)
	if LevelManager.platformer:
		local_added_distance.x = local_target_distance_axis(
			local_player_distance.x,
			MAX_DISTANCE.x / zoom.x,
			framerate_compensation)
	
	# Apply distance
	var added_distance = local_added_distance.rotated(player.gameplay_rotation)
	position += added_distance
	offset = offset.lerp(get_offset_target().rotated(player.gameplay_rotation), 0.125 * framerate_compensation)

	# Clamp bottom edge of the screen to the ground
	var half_screen_height = get_viewport_rect().size.y / 2
	if position.y + half_screen_height / zoom.y > ground_down.DEFAULT_Y + 160:
		position.y = ground_down.DEFAULT_Y + 160 - half_screen_height / zoom.y
	# Same thing for the top edge of the screen
	if position.y - half_screen_height / zoom.y < ground_up.DEFAULT_Y - 160:
		position.y = ground_up.DEFAULT_Y - 160 + half_screen_height / zoom.y


func local_target_distance_axis(distance: float, max_distance: float, framerate_compensation: float) -> float:
	if not freefly:
		return distance * 0.2 * framerate_compensation
	if abs(distance) < max_distance:
		return 0.0
	else:
		return (distance - sign(distance) * max_distance) * 0.2 * framerate_compensation


func get_offset_target() -> Vector2:
	if LevelManager.platformer:
		return Vector2.ZERO + additional_offset
	else:
		return Vector2(
			((DEFAULT_OFFSET.x * player.get_direction() * sign(player.speed_multiplier)) / zoom.x),
			(DEFAULT_OFFSET.y / zoom.y)) * gameplay_offset + additional_offset


func _draw() -> void:
	if not Config.config.draw_debug_overlays:
		return
	draw_set_transform(Vector2.ZERO, player.gameplay_rotation)
	draw_rect(Rect2(-MAX_DISTANCE / zoom, 2 * MAX_DISTANCE / zoom), Color.CYAN, false, 4.0)
	draw_set_transform(Vector2.ZERO, 0.0)
	draw_circle(Vector2.ZERO, 20.0, Color.GREEN, false, 4.0)
	draw_circle(offset.rotated(-rotation), 20.0, Color.MAGENTA, false, 4.0)
