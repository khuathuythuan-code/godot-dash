class_name ReboundComponent
extends Component

var _velocity: float
var sprite: Node2D
var player_distance: float
var player_velocity: Vector2


func _ready() -> void:
	if parent is PadInteractable:
		parent.collision_layer |= 1 << 10 # Velocity redirectors


func _physics_process(delta: float) -> void:
	player_distance = (parent.global_position.rotated(-LevelManager.player.gameplay_rotation).y \
		- LevelManager.player.global_position.rotated(-LevelManager.player.gameplay_rotation).y ) \
	* LevelManager.player.gravity_flip
	var new_player_velocity = LevelManager.player.velocity.rotated(-LevelManager.player.gameplay_rotation) \
	* LevelManager.player.gravity_flip
	if parent.get_overlapping_bodies().is_empty():
		player_velocity = new_player_velocity
	if player_distance > Player.TERMINAL_VELOCITY.y * delta:
		_velocity = player_velocity.y


func _process(_delta: float) -> void:
	if player_velocity.y <= 0:
		sprite.factor = clampf(player_distance / 700, 0, 1)


func get_velocity(player: Player) -> float:
	# Not compatible with dual (can't choose which player to track dynamically so it'll track P1)
	return -_velocity * player.gravity_flip
