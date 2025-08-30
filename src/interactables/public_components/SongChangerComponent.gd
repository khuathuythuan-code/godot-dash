extends Component
class_name SongChangerComponent

@export_global_file(
	"*.mp3",
	"*.ogg",
	"*.wav",
	"load_root:user://created_levels/songs/", # Custom data
	"import_to:user://created_levels/songs/"  # Custom data
) var song_path: String:
	set(value):
		if LevelManager.current_level != null:
			LevelManager.current_level.register_required_song(song_path, value)
		song_path = value
		SongManager.load_song_threaded_request(value)
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var song_start: float


func _ready() -> void:
	super()
	# don't make the request twice, the song_path setter will run at _init
	LevelManager.current_level.register_required_song(song_path, song_path)
	parent.interacted.connect(start)


func start(_player: Player) -> void:
	LevelManager.level_song_player.stream = SongManager.load_song_threaded_get(song_path)
	LevelManager.level_song_player.play(song_start)
