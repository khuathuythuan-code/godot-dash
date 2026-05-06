extends Node

@warning_ignore("unused_signal")
signal update_hsv_watchers
@warning_ignore("unused_signal")
signal level_started

var game_scene: GameScene
var current_level: Level
var current_level_path: String 
var current_level_name: String
var current_level_duration: float = INF
var attempt: int
var level_playing: bool:
	set(value):
		if value == true:
			level_started.emit()
		level_playing = value
var pause_menu: PauseMenu
var stat_pause_menu: StatisticsPauseMenu
var player: Player
var player_duals: Array[Player]
var player_camera: PlayerCamera
var background_sprites: Array[Sprite2D]
var ground_up: GroundObject
var ground_down: GroundObject
var song_player: AudioStreamPlayer
var platformer: bool = false
var practice_mode: bool = false
var practice_level_snapshots: Array[Dictionary]
var touchscreen_controls: TouchScreenControls


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	for directory: String in [Constants.LEVEL_DIR, Constants.SONG_DIR, Constants.FONT_DIR]:
		if not DirAccess.dir_exists_absolute(directory):
			DirAccess.make_dir_recursive_absolute(directory)
