extends GPUParticles2D

@export_storage var saved_preprocess: float = -1.0


func _ready() -> void:
	if saved_preprocess == -1.0:
		saved_preprocess = preprocess
	visible = not (Config.config.hide_portal_particles or (Config.config.hide_particles_editor_only and not Editor.in_editor))
	preprocess = saved_preprocess if Config.config.preprocess_portal_particles or (Config.config.preprocess_particles_editor_only and not Editor.in_editor) else 0.0
