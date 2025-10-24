extends GPUParticles2D
class_name InteractableParticles

@export var type: String
@export_storage var saved_preprocess: float = -1.0


func _ready() -> void:
	if saved_preprocess == -1.0:
		saved_preprocess = preprocess
	visible = (
			Config.config.particles_visibility & UserPreferences.ParticleVisibility[type]
			or (Editor.in_editor and not Config.config.show_particles_in_editor)
	)
	var should_preprocess = (
			Config.config.particles_preprocessing & UserPreferences.ParticlePreprocessing[type]
			or (Editor.in_editor and not Config.config.preprocess_particles_in_editor)
	)
	preprocess = saved_preprocess if should_preprocess else 0.0
