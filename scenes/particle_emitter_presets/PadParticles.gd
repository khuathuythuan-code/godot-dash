extends GPUParticles2D


func _ready() -> void:
	if Config.config.hide_pad_particles:
		if Config.config.hide_particles_editor_only:
			if Editor.in_editor:
				call_deferred("hide")
			set_script(null)
			return
		else:
			call_deferred("hide")
			set_script(null)
			return
	if not Config.config.preprocess_pad_particles:
		if Config.config.preprocess_particles_editor_only:
			if Editor.in_editor:
				preprocess = 0.0
			set_script(null)
			return
		else:
			preprocess = 0.0
			set_script(null)
			return
