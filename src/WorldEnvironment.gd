extends WorldEnvironment


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	environment.glow_enabled = Config.config.world_enviroment_glow
