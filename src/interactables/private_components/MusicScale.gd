extends Node
class_name MusicScale

@onready var parent: Node2D = get_parent()
@onready var initial_scale: Vector2 = parent.scale

func _ready() -> void:
	process_thread_group = Node.PROCESS_THREAD_GROUP_SUB_THREAD

func _process(delta):
	parent.set_deferred("scale", parent.scale.lerp(initial_scale * (LevelManager.current_level.music_scale), 1-exp(-delta * 12)))
