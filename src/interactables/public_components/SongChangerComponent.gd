extends Component

class_name SongChangerComponent

@export_global_file(
	"*.mp3",
	"*.ogg",
	"*.wav",
	"load_root:user://created_levels/songs/", # Custom data
	"import_to:user://created_levels/songs/", # Custom data
)
var path: String:
	set(value):
		if LevelManager.current_level:
			LevelManager.current_level.register_required_song(path, value)
		path = value
		AssetManager.load_song_threaded_request(value)
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var start_offset: float
@export_custom(PROPERTY_HINT_TOOL_BUTTON, "Preview,Play") var preview: Callable = start_preview

var is_previewing: bool


func _ready() -> void:
	# don't make the request twice, the path setter will run at _init
	LevelManager.current_level.register_required_song(path, path)
	parent.interacted.connect(start)


func _validate_property(property: Dictionary) -> void:
	if property.name == "preview" and is_previewing:
		property.hint_string = "Preview,Stop"


func _field_to_data(field_name: String) -> Variant:
	match field_name:
		"preview":
			return null
		_:
			return get(field_name)


func start(_player: Player = null) -> void:
	LevelManager.level_song_player.stream = AssetManager.load_song_threaded_get(path)
	LevelManager.level_song_player.stream.resource_path = path
	LevelManager.level_song_player.play(start_offset)


func start_preview() -> void:
	if is_previewing:
		is_previewing = false
		notify_property_list_changed()
		LevelManager.level_song_player.stop()
		LevelManager.level_song_player.stream = AssetManager.load_song_threaded_get(LevelManager.current_level.song_path)
		return
	is_previewing = true
	notify_property_list_changed()
	start()
