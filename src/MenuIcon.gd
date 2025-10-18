extends Player

class_name MenuIcon

var jumping: bool = false

func _ready() -> void:
	if !Config.config.enable_easter_eggs:
		queue_free()
	platform_on_leave = PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY if not LevelManager.platformer else PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_VELOCITY
	dash_control = null
	_spider_animation_tree = $Icon/Spider/SpiderStateMachine
	_spider_state_machine = _spider_animation_tree["parameters/playback"]
	internal_gamemode = Gamemode.CUBE
	displayed_gamemode = Gamemode.CUBE
	apply_floor_snap()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	# Get velocity
	if internal_gamemode in [Gamemode.BALL, Gamemode.SPIDER]:
		gravity_flip = 1
	up_direction = Vector2.UP.rotated(gameplay_rotation) * sign(gravity_flip)
	var jump_state = _get_jump_state()
	velocity = _compute_velocity(delta, velocity, get_direction(), jump_state)
	
	# Slope collision resolution
	if not $SlopeShapecast.is_colliding() and $GroundCollider.shape is CircleShape2D:
		$GroundCollider.shape = default_collider
		$SolidOverlapCheck/SolidOverlapCheckCollider.shape = default_collider
		$Icon/Spider/SpiderCast.shape = default_collider
	floor_snap_length = 0.0 if LevelManager.platformer and internal_gamemode == Gamemode.WAVE else LevelManager.CELL_SIZE * 0.5 * speed_multiplier
	for i in range(10):
		last_collision = move_and_collide(velocity * delta, true)
		$GroundCollider.rotation = gameplay_rotation
		_handle_collision(last_collision, i != 0)
		# Collide down with solids so the wave can crash into them
		if internal_gamemode == Gamemode.WAVE and allow_wave_slide_count == 0:
			last_collision = move_and_collide(speed.y * Vector2.DOWN * delta, true)
			$GroundCollider.rotation = gameplay_rotation
			_handle_collision(last_collision, true)

	# Apply movement
	move_and_slide()
	_position_check()
	
	# Sprite updates
	_rotate_sprite_degrees(delta, jump_state)
	%GroundParticles.emitting = is_on_floor() and not is_zero_approx(velocity.rotated(-gameplay_rotation).x) and not dash_control
	match displayed_gamemode:
		Gamemode.SPIDER:
			_update_spider_state_machine(jump_state)
		Gamemode.SWING:
			_update_swing_fire(delta)
	_update_wave_trail(delta)
	
	# Instantiate spider trail if needed
	if _last_spider_trail != null:
		add_child(_last_spider_trail)
		_last_spider_trail.trail_global_position = $Icon/Spider/SpiderCast/SpiderTrailSpawnPoint.global_position if horizontal_direction > 0 \
			else $Icon/Spider/SpiderCast/SpiderTrailSpawnPointReverse.global_position
		_last_spider_trail.displayed_scale_y = abs(_last_spider_trail_height) * sign(gravity_flip)
		_last_spider_trail.displayed_scale_x = -horizontal_direction
		_last_spider_trail = null
	
	# 0x speed portal position nudge
	if speed_0_portal_control:
		var rotation_local_global_position = global_position.rotated(-gameplay_rotation)
		var rotation_local_portal_global_position = speed_0_portal_control.parent.global_position.rotated(-gameplay_rotation)
		var rotation_local_velocity = velocity.rotated(-gameplay_rotation)
		# Update ship icon by running `displayed_gamemode` setter
		displayed_gamemode = displayed_gamemode
		global_position = Vector2(
			rotation_local_global_position.lerp(rotation_local_portal_global_position, 0.3 * delta * 60).x,
			rotation_local_global_position.y
		).rotated(gameplay_rotation)
		velocity = Vector2(
			0.0,
			rotation_local_velocity.y
		).rotated(gameplay_rotation)
		if is_equal_approx(rotation_local_global_position.x, rotation_local_portal_global_position.x):
			speed_0_portal_control = null
	
	if _snap_sprite_rotation:
		if _snap_sprite_rotation_frames > 0:
			_snap_sprite_rotation_frames -= 1
		elif _snap_sprite_rotation_frames == 0:
			_snap_sprite_rotation = false

#
# func _handle_collision(collision: KinematicCollision2D, is_refine_iteration: bool) -> void:
# 	if not collision:
# 		return
# 	var collision_angle: float = collision.get_angle(up_direction)
# 	var is_floor: bool = collision_angle <= deg_to_rad(10.0)
# 	var is_ceiling: bool = collision_angle >= deg_to_rad(180.0 - 10.0)
# 	var is_wall: bool = collision_angle > floor_max_angle and collision_angle < PI - floor_max_angle
# 	var is_slope := not is_floor and not is_ceiling
# 	if not LevelManager.platformer and ((is_ceiling and allow_ceiling_hit_count == 0) or is_wall) or (internal_gamemode == Gamemode.WAVE and allow_wave_slide_count == 0):
# 		if collision.get_collider().collision_layer & 1 << 1:
# 			collision.get_collider().collision_layer = 1 << 9
# 			collision.get_collider().get_node("Hitbox").debug_color.s = 0.0 # DEBUG: Hardcoded name for hitbox color
# 	if is_ceiling and allow_ceiling_hit_count > 0:
# 		hit_ceiling.emit(self)
# 	if not is_refine_iteration:
# 		if is_slope:
# 			$GroundCollider.shape = slope_collider
# 			$Icon/Spider/SpiderCast.shape = slope_collider
# 			$SolidOverlapCheck/SolidOverlapCheckCollider.shape = slope_collider
# 		if is_floor and not dash_control:
# 			var ground_hit_particles: GPUParticles2D = GROUND_HIT_PARTICLE.instantiate()
# 			%GroundParticles.add_child(ground_hit_particles)
#
#
# func get_floor_angle_signed(last_slide: bool, jump_state: int) -> float:
# 	var floor_normal: Vector2
# 	if last_slide:
# 		floor_normal = get_last_slide_collision().get_normal()
# 	else:
# 		floor_normal = get_floor_normal()
# 	var floor_angle: float
# 	if _is_flying_gamemode and is_on_ceiling() and jump_state == 1:
# 		var local_up_direction: Vector2 = Vector2.DOWN.rotated(gameplay_rotation) * sign(gravity_flip)
# 		floor_angle = snappedf(rad_to_deg(floor_normal.angle_to(local_up_direction)), 0.01)
# 	else:
# 		floor_angle = snappedf(rad_to_deg(floor_normal.angle_to(up_direction)), 0.01)
# 	# Iron out jittery angles
# 	if abs(floor_angle - floor_angle_average) > 0.5:
# 		floor_angle_history.clear()
# 	if len(floor_angle_history) > 10:
# 		floor_angle_history.pop_front()
# 	floor_angle_history.append(floor_angle)
# 	floor_angle_average = ArrayUtils.transform(floor_angle_history, ArrayUtils.Transformation.MEAN)
# 	floor_angle_average = snappedf(floor_angle_average, 0.01)
# 	if is_equal_approx(abs(floor_angle), 90.0):
# 		return 0.0
# 	return deg_to_rad(floor_angle)
#
#
# func get_direction() -> int:
# 	var direction: int
# 	if LevelManager.platformer:
# 		direction = int(Input.get_axis("move_left", "move_right"))
# 		if direction != 0:
# 			horizontal_direction = direction
# 	else:
# 		direction = horizontal_direction
# 	return direction
#
# Need this or else no jumping
func _get_jump_state() -> int:
	var jump_state: int

	if _click_buffer_state == ClickBufferState.NOT_HOLDING and jumping and not (is_on_floor() or is_on_ceiling()) \
			and internal_gamemode != Gamemode.SHIP and internal_gamemode != Gamemode.SWING and internal_gamemode != Gamemode.WAVE:
		_click_buffer_state = ClickBufferState.BUFFERING
	if _click_buffer_state == ClickBufferState.BUFFERING and not orb_queue.is_empty():
		_click_buffer_state = ClickBufferState.JUMPING
	if Input.is_action_just_released("jump") or ((is_on_floor() or is_on_ceiling()) and not jumping):
		_click_buffer_state = ClickBufferState.NOT_HOLDING

	if jump_hold_disabled:
		jump_state = -1
		if jumping and (is_on_floor() or is_on_ceiling() or coyote_time > 0):
			jump_hold_disabled = false
	elif internal_gamemode == Gamemode.CUBE:
		jump_state = 1 if jumping and (is_on_floor() or coyote_time > 0) else -1
	elif internal_gamemode == Gamemode.ROBOT:
		if jumping and (is_on_floor() or coyote_time > 0):
			$RobotTimer.start(0.25)
		if Input.is_action_just_released("jump"):
			$RobotTimer.stop()
		jump_state = 1 if jumping and $RobotTimer.get_time_left() > 0 else -1
	elif internal_gamemode == Gamemode.SHIP or (internal_gamemode == Gamemode.WAVE and not LevelManager.platformer):
		jump_state = 1 if jumping else -1
	elif internal_gamemode == Gamemode.WAVE and LevelManager.platformer:
		jump_state = 0
		if jumping: jump_state = 1
		if Input.is_action_pressed("platformer_wave_down"): jump_state = -1
	elif internal_gamemode == Gamemode.UFO or internal_gamemode == Gamemode.SWING:
		jump_state = 1 if jumping else -1
		jumping = false
	elif internal_gamemode == Gamemode.BALL or internal_gamemode == Gamemode.SPIDER:
		jump_state = 1 if (jumping and (is_on_floor() or is_on_ceiling())) else -1

	if get_viewport().gui_get_hovered_control() != null:
		if get_viewport().gui_get_hovered_control().name == "EditorViewport":
			return jump_state
		else:
			return 0 if LevelManager.platformer else -1

	return jump_state

# Need this or else crash
func _compute_velocity(delta: float,
		previous_velocity: Vector2,
		direction: int, jump_state: int) -> Vector2:
	var _velocity: Vector2 = previous_velocity.rotated(-gameplay_rotation)
	_is_flying_gamemode = (internal_gamemode == Gamemode.SHIP or internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.WAVE)
	
	if _spider_jump_invulnerability_frames > 0: _spider_jump_invulnerability_frames -= 1
	
	#region Slope physics
	var slope_velocity: Vector2
	if $GroundCollider.shape is CircleShape2D and get_last_slide_collision() != null:
		var floor_angle := get_floor_angle_signed(true, jump_state)
		# 90° collision warp prevention
		if pingpong(floor_angle, PI/2) < floor_max_angle:
			slope_velocity.y = tan(-floor_angle) * abs(_velocity.x) * direction
	#endregion

	if (internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.BALL) and jump_state == 1 and orb_queue.is_empty():
		gravity_flip *= -1

	$GroundCollider.rotation = gameplay_rotation
	$SolidOverlapCheck.rotation = gameplay_rotation
	$KillColliderSolid.rotation = gameplay_rotation
	$KillColliderRectangularHazard.rotation = gameplay_rotation
	$KillColliderCircularHazard.rotation = gameplay_rotation
	$GroundRaycast.rotation = gameplay_rotation
	$GroundRaycast.scale.y = gravity_flip
	$SlopeShapecast.rotation = gameplay_rotation
	$SlopeShapecast.scale.y = gravity_flip

	#region Apply Gravity
	if not dash_control:
		if internal_gamemode == Gamemode.SHIP:
			_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier * jump_state * -1 * FLY_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif internal_gamemode == Gamemode.SWING:
			_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier * FLY_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif internal_gamemode == Gamemode.WAVE:
			_velocity.y = SPEED.x * gravity_flip * gravity_multiplier * jump_state * -1
			if speed_multiplier > 0: _velocity.y *= speed_multiplier
			if player_scale == PlayerScale.MINI:
				_velocity.y *= 2
			elif player_scale == PlayerScale.BIG:
				_velocity.y *= 0.5
		elif internal_gamemode == Gamemode.SPIDER:
			_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier * jump_state * -1 * SPIDER_GRAVITY_MULTIPLIER
			_velocity.y = clamp(_velocity.y, -TERMINAL_VELOCITY.y, TERMINAL_VELOCITY.y)
		elif not is_on_floor() and not $GroundRaycast.is_colliding():
			if internal_gamemode == Gamemode.UFO:
				_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier * UFO_GRAVITY_MULTIPLIER
			else:
				_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier
	#endregion
	
	var flying_gamemode_slope_boost: bool = _is_flying_gamemode and (
		(is_on_ceiling() and jump_state >= 0) or
		(is_on_floor()
			and get_last_slide_collision() != null
			and get_floor_angle_signed(true, jump_state) != 0.0
			and get_direction() != 0
			and jump_state == 1)
	)
	var isnt_jumping: bool = is_on_floor() and jump_state <= 0 and not _deferred_velocity_redirect

	if pad_queue.is_empty() and flying_gamemode_slope_boost or isnt_jumping:
		_velocity.y = slope_velocity.y

	#region Apply pads velocity
	if not pad_queue.is_empty():
		var colliding_pad: PadInteractable = pad_queue.pop_front()
		for component in colliding_pad.components:
			if internal_gamemode != Gamemode.WAVE and (component is JumpBoostComponent or (component is ReboundComponent and (not is_on_floor() or _deferred_velocity_redirect))):
				if internal_gamemode == Gamemode.SPIDER:
					_velocity.y = component.get_velocity(self) * SPIDER_BOUNCE_MULTIPLIER
				else:
					_velocity.y = component.get_velocity(self)
				if displayed_gamemode == Gamemode.SPIDER:
					_spider_state_machine.travel("jump")
			elif component is SpiderDashComponent:
				component.set_dash_flip_state(self)
				gravity_flip *= -1
				position += Vector2.DOWN.rotated(gameplay_rotation) * _get_spider_velocity_delta()
				defer_snap_sprite_rotation()
				jump_hold_disabled = true
				_velocity.y = gravity_multiplier * gravity_flip * 10
	#endregion

	#region Handle jump.
	if jump_state == 1 and pad_queue.is_empty() and orb_queue.is_empty():
		if _is_flying_gamemode:
			pass
		elif internal_gamemode == Gamemode.SPIDER:
			gravity_flip *= -1
			position += Vector2.DOWN.rotated(gameplay_rotation) * _get_spider_velocity_delta()
			defer_snap_sprite_rotation()
		elif internal_gamemode == Gamemode.BALL:
			_velocity.y = speed.y * gravity_flip * 0.5
		elif internal_gamemode == Gamemode.ROBOT:
			_velocity.y = SPEED.x * gravity_flip * -1
		elif internal_gamemode == Gamemode.UFO:
			_velocity.y = -speed.y * gravity_flip * UFO_GRAVITY_MULTIPLIER
		else:
			_velocity.y = -speed.y * gravity_flip
	#endregion

	if not LevelManager.platformer or (LevelManager.platformer and internal_gamemode == Gamemode.WAVE):
		if direction:
			_velocity.x = direction * speed.x * speed_multiplier
		else:
			_velocity.x = 0
	else:
		if direction:
			_velocity.x = move_toward(
				_velocity.x,
				direction * speed.x * speed_multiplier,
				speed.x * delta * speed_multiplier * PLATFORMER_ACCELERATION)
		else:
			_velocity.x = move_toward(
				_velocity.x,
				0.0,
				speed.x * delta * speed_multiplier * PLATFORMER_ACCELERATION)

	
	var visual_gameplay_rotation_degrees: float = round(gameplay_rotation_degrees)
	var gameplay_rotation_in_180_quadrant: bool = abs(visual_gameplay_rotation_degrees) > 135.0 and abs(visual_gameplay_rotation_degrees) < 225.0
	var flipped_controls_in_90_quadrant: bool = gravity_flip < 0 and abs(visual_gameplay_rotation_degrees) > 45.0 and abs(visual_gameplay_rotation_degrees) < 135.0

	if LevelManager.platformer and abs(_velocity.x) < 10.0 and (gameplay_rotation_in_180_quadrant or flipped_controls_in_90_quadrant):
		gameplay_rotation_degrees = wrapf((abs(gameplay_rotation_degrees) - 180.0) * signf(gameplay_rotation_degrees), -180.0, 180.0)
		gravity_flip *= -1
	
	#region Apply orbs velocity
	if not orb_queue.is_empty() and (
			_click_buffer_state == ClickBufferState.JUMPING
			or (jump_state == 1 and not _is_flying_gamemode and not _click_buffer_state == ClickBufferState.BUFFER_USED)
			or (jumping and _is_flying_gamemode)):
		var colliding_orb: OrbInteractable = orb_queue.pop_front()
		_click_buffer_state = ClickBufferState.BUFFER_USED
		colliding_orb.interacted.emit(self)
		for component in colliding_orb.components:
			if internal_gamemode != Gamemode.WAVE and (component is JumpBoostComponent or component is ReboundComponent):
				if internal_gamemode == Gamemode.SPIDER:
					_velocity.y = component.get_velocity(self) * SPIDER_BOUNCE_MULTIPLIER
				else:
					_velocity.y = component.get_velocity(self)
				if displayed_gamemode == Gamemode.SPIDER:
					_spider_state_machine.travel("jump")
			elif component is SpiderDashComponent:
				component.set_dash_flip_state(self)
				gravity_flip = -sign($Icon/Spider/SpiderCast.scale.y)
				position += Vector2.DOWN.rotated(gameplay_rotation) * _get_spider_velocity_delta()
				defer_snap_sprite_rotation()
				jump_hold_disabled = true
				_velocity.y = gravity_multiplier * gravity_flip * 10
		if not colliding_orb.has(SingleUsageComponent):
			orb_queue.append(colliding_orb)
	#endregion

	#region Dash orb velocity
	if dash_control:
		_velocity = dash_control.path.get_velocity(self)
		if Input.is_action_just_released("jump"):
			stop_dash()
	#endregion

	var is_falling: bool = _velocity.y * gravity_flip > 0
	if is_on_floor():
		coyote_time = 2.0/60.0
	else:
		if is_falling:
			coyote_time = max(0, coyote_time - delta)
		else:
			coyote_time = 0.0

	_deferred_velocity_redirect = _ensure_velocity_redirect(delta, _velocity.rotated(gameplay_rotation))

	return _velocity.rotated(gameplay_rotation)


# Need this or else crash
func _update_wave_trail(delta: float) -> void:
	var wave_trail_width := WAVE_TRAIL_WIDTH
	if player_scale == PlayerScale.MINI:
		wave_trail_width *= PLAYER_SCALE_MINI.y
	elif player_scale == PlayerScale.BIG:
		wave_trail_width *= PLAYER_SCALE_BIG.y
	%WaveTrail.width = lerpf(%WaveTrail.width, wave_trail_width, 0.25 * delta * 60)
	%WaveTrailInner.width = lerpf(%WaveTrailInner.width, wave_trail_width * 0.5, 0.25 * delta * 60)
	if internal_gamemode == Gamemode.WAVE:
		%WaveTrail.modulate.a = 1.0
		%WaveTrailInner.modulate.a = 1.0
		%WaveTrail.length = lerpf(%WaveTrail.length, WAVE_TRAIL_LENGTH, delta * 60 * 0.2)
		%WaveTrailInner.length = lerpf(%WaveTrail.length, WAVE_TRAIL_LENGTH, delta * 60 * 0.2)
	else:
		%WaveTrail.length = 0
		%WaveTrailInner.length = 0
		%WaveTrail.modulate.a = move_toward(%WaveTrail.modulate.a, 0.0, delta * 60 * 0.2)
		%WaveTrailInner.modulate.a = move_toward(%WaveTrailInner.modulate.a, 0.0, delta * 60 * 0.2)
		if is_zero_approx(%WaveTrail.modulate.a):
			%WaveTrail.clear_points()
		if is_zero_approx(%WaveTrailInner.modulate.a):
			%WaveTrailInner.clear_points()


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


func _on_kill_collider_solid_body_entered(_body:Node2D) -> void:
	if _spider_jump_invulnerability_frames == 0:
		$DeathAnimator.play("DeathAnimation")


func _on_kill_collider_hazard_body_entered(_body:Node2D) -> void:
	if _spider_jump_invulnerability_frames == 0:
		$DeathAnimator.play("DeathAnimation")


func stop_dash() -> void:
	$DashParticles.emitting = false
	$DashFlame.hide()
	dash_control = null


func _on_solid_overlap_check_body_exited(body:Node2D) -> void:
	body = body as CollisionObject2D
	body.collision_layer = 1 << 1
	body.get_node("Hitbox").debug_color = Color("#0012b340") # DEBUG: Hardcoded name for hitbox color


func _on_jump_cooldown_timeout() -> void:
	if position.y < -128:
		jumping = false
		return
	if _is_flying_gamemode:
		jumping = randi_range(0, 1) == 1
		return
	jumping = randi_range(0, 2) == 1

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
	if position.y < -128:
		if internal_gamemode == Gamemode.SWING:
			gravity_flip = 1
			jumping = false
