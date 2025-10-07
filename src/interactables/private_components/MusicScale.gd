extends Node
class_name MusicScale

@onready var parent: Node2D = get_parent()
@onready var initial_scale: Vector2 = parent.scale
@onready var music_scale: float = LevelManager.current_level.music_scale

func _ready() -> void:
	process_thread_group = Node.PROCESS_THREAD_GROUP_SUB_THREAD

func _process(delta):
	parent.set_thread_safe("scale", parent.scale.lerp(initial_scale * (music_scale), 1-exp(-delta * 12)))
	#parent.scale = parent.scale.lerp(initial_scale * (music_scale), 1-exp(-delta * 12))
