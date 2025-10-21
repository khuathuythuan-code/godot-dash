extends Player
class_name MenuIcon

var _last_jump: int = 0
var _last_jump_state: int = false


func _process(_delta: float) -> void:
	_position_check()


func _get_jump_state() -> int:
	var jump_state: int
	
	if not Time.get_ticks_msec() - _last_jump > randi_range(75, 200):
		if internal_gamemode == Gamemode.CUBE and not is_on_floor_only():
			return -1
		elif internal_gamemode == Gamemode.UFO and _last_jump_state == 1:
			return -1
		return _last_jump_state
	_last_jump = Time.get_ticks_msec()

	jump_state = -1

	match internal_gamemode:
		Gamemode.CUBE when is_on_floor():
			if randi_range(0, 2) == 0:
				jump_state = 1
		Gamemode.SHIP, Gamemode.WAVE:
			if randi_range(0, 1) == 0:
				jump_state = 1
		Gamemode.ROBOT:
			if is_on_floor():
				if randi_range(0, 2) == 0:
					jump_state = 1
					$RobotTimer.start(0.25)
			else:
				if randi_range(0, 4) == 0:
					$RobotTimer.stop()
		Gamemode.UFO:
			if randi_range(0, 1) == 0:
				jump_state = 1
		Gamemode.SWING when Time.get_ticks_msec() - _last_jump > 200:
			if randi_range(0, 1) == 0:
				jump_state = 1
		Gamemode.BALL, Gamemode.SPIDER:
			if randi_range(0, 2) == 0:
				jump_state = 1
	if position.y < 256:
		match internal_gamemode:
			Gamemode.SHIP, Gamemode.WAVE, Gamemode.UFO:
				jump_state = -1
			Gamemode.SWING, Gamemode.BALL, Gamemode.SPIDER:
				gravity_flip = 1
	elif position.y > 640:
		match internal_gamemode:
			Gamemode.SHIP, Gamemode.WAVE, Gamemode.UFO:
				jump_state = 1
			Gamemode.SWING:
				gravity_flip = -1
	_last_jump_state = jump_state
	return jump_state


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
		internal_gamemode = displayed_gamemode


func _on_death_restart() -> void:
	pass
