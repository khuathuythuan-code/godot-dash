extends MusicScaleAttribute
class_name MusicScaleParticlesAttribute

@onready var parent := get_parent()


func _ready() -> void:
	var particles_emitter := parent.get_node_or_null(^"ParticleEmitter")
	if particles_emitter:
		print("a")
		NodeUtils.get_node_or_add(particles_emitter, "MusicScale", MusicScale)


func _exit_tree() -> void:
	var particles_emitter := parent.get_node_or_null(^"ParticleEmitter")
	if particles_emitter:
		particles_emitter.get_node_or_null(^"MusicScale").queue_free()

