extends GPUParticles2D


func _ready() -> void:
	if Config.config.hide_orb_particles:
		if Config.config.hide_particles_editor_only:
			if Editor.in_editor: # IDK HOW THIS WORKS
				call_deferred("hide")
		else:
			call_deferred("hide")
			set_script(null)
			return
	if not Config.config.preprocess_orb_particles:
		if Config.config.preprocess_particles_editor_only:
			if Editor.in_editor: # IDK HOW THIS WORKS
				preprocess = 0.0
		else:
			preprocess = 0.0
			set_script(null)
			return
