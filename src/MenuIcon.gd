extends Player

class_name MenuIcon

var jumping: bool = false

func _ready() -> void:
	super()
	if not Config.config.enable_easter_eggs:
		queue_free()


func _process(_delta: float) -> void:
	_position_check()

func _player_death() -> void:
	if _dead:
		return
	_dead = true
	speed_multiplier = 0.0
	$Icon.hide()
	$DeathEffect.frame = 0
	$DeathEffect.play()
	$DeathParticles.restart()
	$DashParticles.emitting = false
	%GroundParticles.emitting = false
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/DeathSound.mp3")
	await get_tree().create_timer(0.5).timeout
	speed_multiplier = 1.0
	position.x = 10000
	_dead = false
	$Icon.show()
	_position_check()

func _on_death_restart() -> void:
	pass


func _position_check() -> void:
	if position.x > DisplayServer.screen_get_size().x + 1024:
		position.x = -512.0
		position.y = randi_range(816, 300)
		# Excludes Gamemode.BALL and Gamemode.SPIDER since there is no roof
		var index: int = 0 # Prevents infinite looping (fallback)
		while (displayed_gamemode == internal_gamemode or displayed_gamemode == Gamemode.BALL or displayed_gamemode == Gamemode.SPIDER) and index < 100:
			index += 1
			displayed_gamemode = randi_range(0, 7) as Gamemode
			player_scale = randi_range(0, 1) as PlayerScale
			gravity_flip = 1
			jumping = randi_range(0, 1) == 0
		internal_gamemode = displayed_gamemode
