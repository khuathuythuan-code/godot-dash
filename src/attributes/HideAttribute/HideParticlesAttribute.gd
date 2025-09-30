extends HideAttribute
class_name HideParticlesAttribute
@onready var parent := get_parent()

func _ready() -> void:
	var base := parent.get_node_or_null(^"ParticleEmitter")
	if base:
		base.hide()

func _exit_tree() -> void:
	var base := parent.get_node_or_null(^"ParticleEmitter")
	if base:
		base.show()
