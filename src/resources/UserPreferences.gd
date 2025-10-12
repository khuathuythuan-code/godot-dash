class_name UserPreferences extends Resource

@export_group("Graphics")
@export_range(0, 60, 1, "or_greater") var max_fps: int = 60
@export var vsync: int
@export var window_mode: int
@export var anti_aliasing: int = 0

@export_group("Performance")
@export var hide_particles_editor_only: bool = true
@export var hide_orb_particles: bool = false
@export var hide_pad_particles: bool = false
@export var hide_portal_particles: bool = false
@export var hide_speedportal_particles: bool = false
@export var preprocess_particles_editor_only: bool = true
@export var preprocess_orb_particles: bool = true
@export var preprocess_pad_particles: bool = true
@export var preprocess_portal_particles: bool = true
@export var preprocess_speedportal_particles: bool = true

@export_subgroup("Culling")
@export var cull_hitboxes: bool = false
@export var cull_sprites: bool = false
@export var hitboxes_cull_limit: int = 4
@export var sprites_cull_limit: int = 32
@export var cull_interval: float = 0.1

@export_group("Audio")
@export_range(0, 1, .05) var master_audio_level: float = 1.0
@export_range(0, 1, .05) var music_audio_level: float = 1.0
@export_range(0, 1, .05) var game_sfx_audio_level: float = 1.0
@export_range(0, 1, .05) var in_level_sfx_audio_level: float = 1.0
@export var mute_game_on_unfocus: bool = true

@export_group("Keybinds")
@export_storage var input_map: Dictionary[StringName, Array] = {} # Dictionary[StringName, Array[InputEvent]]

@export_group("Editor")
@export var hide_grid_on_playtest: bool = true
@export var autosave_delay: float
@export var selection_zone_color := Color.GREEN
@export_range(0, 1, .05) var selection_zone_fill_alpha := 0.2
@export var trigger_hitbox_color := Color.CYAN
@export_range(0, 1, .05) var trigger_hitbox_fill_alpha := 0.2


@export_group("Debug")
@export var draw_debug_overlays: bool
@export var touch_screen_mode: int = 2
@export var touch_screen: bool = false # <-- Use this one

@export_group("Easter Eggs")
@export var enable_easter_eggs: bool


func save() -> void:
	ResourceSaver.save(self, "user://user_prefs.tres")


static func load_or_create() -> UserPreferences:
	var user_preferences: UserPreferences = load("user://user_prefs.tres") as UserPreferences
	if not user_preferences:
		user_preferences = UserPreferences.new()
	return user_preferences
