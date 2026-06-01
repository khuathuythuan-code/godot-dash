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
		var target_y: float = (
		ground_position * GroundData.distance
		* zoom_factor.y
		+ GroundData.center.y - GroundData.offset
		)
		# Snap về đường grid gần nhất
		target_y = snappedf(target_y, Constants.CELL_SIZE)+ 32
		
			# Giới hạn ground_down không xuống quá default_y
		if ground_position == 1:
			target_y = min(target_y, default_y)
		# Giới hạn ground_up không lên quá default_y
		else:
			target_y = max(target_y, default_y)
		global_position.y = lerp(global_position.y, target_y, 0.08 * delta * 60)
	else:
		global_position = global_position.lerp(
			Vector2(global_position.x, default_y),
			0.2 * delta * 60,
		)
	_previous_camera_rotation = LevelManager.player_camera.rotation


## Sync the rotation with P1's [member Player.gameplay_rotation] on gamemode change.
func _sync_rotation(new_gameplay_rotation: float) -> void:
	rotation = new_gameplay_rotation
