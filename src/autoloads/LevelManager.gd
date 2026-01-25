extends Node

const CELL_SIZE: int = 128

signal update_hsv_watchers

var game_scene: GameScene
var current_level: Level
var current_level_path: String
var current_level_name: String
var current_level_duration: float = INF
var attempt: int
var level_playing: bool
var pause_manager: Node
var player: Player
var player_duals: Array[Player]
var player_camera: PlayerCamera
var background_sprites: Array[Sprite2D]
var ground_up: GroundObject
var ground_down: GroundObject
var level_song_player: AudioStreamPlayer
var platformer: bool = false
var practice_mode: bool = false
var practice_level_snapshots: Array[Dictionary]


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	if not DirAccess.dir_exists_absolute("user://created_levels/levels"):
		DirAccess.make_dir_recursive_absolute("user://created_levels/levels")
	if not DirAccess.dir_exists_absolute("user://created_levels/songs"):
		DirAccess.make_dir_recursive_absolute("user://created_levels/songs")
	if not DirAccess.dir_exists_absolute("user://created_levels/fonts"):
		DirAccess.make_dir_recursive_absolute("user://created_levels/fonts")
