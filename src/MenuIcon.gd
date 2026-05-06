class_name MenuIcon
extends Player

var _last_jump: int = 0
var _last_jump_state: int = false
var _jump_interval: int = 0


func _ready() -> void:
	if not Config.enable_title_screen_icons:
		queue_free()
		return
	super()
	%DebugOverlays.hide()


func _process(_delta: float) -> void:
	_global_position_check()


func _should_process() -> bool:
	return not dead


func _get_jump_state() -> int:
	var jump_state: int
	if not Time.get_ticks_msec() - _last_jump > _jump_interval:
		if internal_gamemode == Gamemode.CUBE and not is_on_floor_only():
			return -1
		elif internal_gamemode == Gamemode.UFO and _last_jump_state == 1:
			return -1
		_last_jump_state = _prevent_leave_screen(internal_gamemode, _last_jump_state)
		return _last_jump_state
	_last_jump = Time.get_ticks_msec()
	_jump_interval = randi_range(75, 200)
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

	jump_state = _prevent_leave_screen(internal_gamemode, jump_state)

	_last_jump_state = jump_state
	return jump_state


func _playback_replay() -> void:
	return


func _reset_replay() -> void:
	return


func _player_death() -> void:
	if dead:
		return
	dead = true
	speed_multiplier = 0.0
	velocity = Vector2.ZERO
	$Icon.hide()
	$DeathEffect.frame = 0
	$DeathEffect.play()
	$DeathParticles.restart()
	$DashParticles.emitting = false
	%GroundParticles.emitting = false
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/DeathSound.mp3")
	await get_tree().create_timer(0.5).timeout
	speed_multiplier = 1.0
	global_position.x = 10000
	dead = false
	$Icon.show()
	_global_position_check()


func _prevent_leave_screen(gamemode: Gamemode, original_value: int = -1) -> int:
	match gamemode:
		Gamemode.WAVE, Gamemode.UFO: # Wave and UFO accelerate instantly so we can be nicer
			if position.y < 128:
				return -1
			if position.y > 816:
				return 1
		Gamemode.SHIP:
			match player_scale:
				PlayerScale.NORMAL:
					if position.y < 256 + velocity.y * velocity.y / Engine.physics_ticks_per_second / 28:
						return -1
					if position.y > 532: # Don't do -^ for this one cuz janky movement
						return 1
				PlayerScale.MINI:
					if position.y < 256 + velocity.y * velocity.y / Engine.physics_ticks_per_second / 28:
						return -1
					if position.y > 512: # miniship accel is kinda slow
						return 1
		Gamemode.SWING:
			match player_scale:
				PlayerScale.NORMAL:
					if position.y < 256 + velocity.y * velocity.y / Engine.physics_ticks_per_second / 28 and gravity_flip == -1:
						return 1
					if position.y > 532 and gravity_flip == 1:
						return 1
				PlayerScale.MINI:
					if position.y < 256 + velocity.y * velocity.y / Engine.physics_ticks_per_second / 28 and gravity_flip == -1:
						return 1
					if position.y > 512 and gravity_flip == 1: # miniswing accel is kinda slow
						return 1

	return original_value


func _global_position_check() -> void:
	if global_position.x > DisplayServer.screen_get_size().x + 1024:
		%Trail.clear_points()
		global_position.x = -512.0
		global_position.y = randi_range(816, 300)
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
