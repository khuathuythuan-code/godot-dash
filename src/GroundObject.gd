class_name GroundObject
extends Node2D

const LERP_FACTOR: float = 30

@export var default_y: float
@export_enum("Up:-1", "Down:1") var ground_position: int = 1

var _previous_camera_rotation: float


func _ready() -> void:
	match ground_position:
		1:
			LevelManager.ground_down = self
		-1:
			LevelManager.ground_up = self


func _physics_process(delta: float) -> void:
	if LevelManager.player_camera == null:
		return
	if get_viewport().get_camera_2d() != LevelManager.player_camera:
		return
	var zoom_factor: Vector2 = PlayerCamera.DEFAULT_ZOOM / LevelManager.player_camera.zoom
	# var zoom_factor := Vector2.ONE
	if not LevelManager.player_camera.freefly:
		var global_position_rotated: Vector2 = global_position.rotated(LevelManager.player.gameplay_rotation)
		global_position_rotated = global_position_rotated.lerp(
			Vector2(
				GroundData.center.x,
				(
					(ground_position * GroundData.distance)
					* zoom_factor.y
					+ GroundData.center.y - GroundData.offset
				),
			),
			0.2 * delta * 60,
		)
		global_position = global_position_rotated.rotated(-LevelManager.player.gameplay_rotation)
	else:
		global_position = global_position.lerp(
			Vector2(global_position.x, default_y),
			0.2 * delta * 60,
		)
	_previous_camera_rotation = LevelManager.player_camera.rotation


## Sync the rotation with P1's [member Player.gameplay_rotation] on gamemode change.
func _sync_rotation(new_gameplay_rotation: float) -> void:
	rotation = new_gameplay_rotation
