class_name Player
extends CharacterBody2D

signal hit_ceiling(player: Player)

enum Gamemode {
	CUBE,
	SHIP,
	UFO,
	BALL,
	WAVE,
	ROBOT,
	SPIDER,
	SWING,
}

enum ClickBufferState {
	NOT_HOLDING,
	BUFFERING,
	JUMPING,
	BUFFER_USED,
}

enum PlayerScale {
	MINI,
	NORMAL,
	BIG,
}

#region Constants
const GRAVITY: float = 5000.0 * 2
const SPEED := Vector2(625.0 * 2, 1100.0 * 2)
const SPEED_MINI := Vector2(625.0 * 2, 800.0 * 2)
const SPEED_BIG := Vector2(625.0 * 2, 1500.0 * 2)
const TERMINAL_VELOCITY := Vector2(0.0 * 2, 1500.0 * 2)
const FLY_TERMINAL_VELOCITY := Vector2(0.0 * 2, 900.0 * 2)
const FLY_GRAVITY_MULTIPLIER: float = 0.5
const UFO_GRAVITY_MULTIPLIER: float = 0.7
const SPIDER_GRAVITY_MULTIPLIER: float = 0.65
const PLAYER_SCALE_WAVE := Vector2(0.6, 0.6)
const PLAYER_SCALE_MINI := Vector2(0.6, 0.6)
const PLAYER_SCALE_NORMAL := Vector2.ONE
const PLAYER_SCALE_BIG := Vector2(1.4, 1.4)
const WAVE_TRAIL_WIDTH: float = 50.0
const WAVE_TRAIL_LENGTH: int = 250
const SPIDER_TRAIL: PackedScene = preload("res://scenes/components/game_components/SpiderTrail.tscn")
const DASH_BOOM: PackedScene = preload("res://scenes/components/game_components/DashBoom.tscn")
const GROUND_HIT_PARTICLE: PackedScene = preload("uid://c3pbl5e1vp2ck")
const UFO_PARTICLE: PackedScene = preload("uid://nt6jgd7lk03t")
const ICON_LERP_FACTOR := 0.5
const SHIP_ROTATION_LERP_FACTOR := 0.15
const PLATFORMER_ACCELERATION := 5.0
const ENSURE_VELOCITY_REDIRECT_SAFE_MARGIN := 2.0
const SPIDER_BOUNCE_MULTIPLIER := 0.65
#endregion

#region Bit Flags
const EVALUATE_CLICK_BUFFER := 1
#endregion

@export var displayed_gamemode: Gamemode:
	set(value):
		displayed_gamemode = value
		update_player_scale(false)
		for icon in $Icon.get_children():
			if icon.gamemode != value:
				icon.hide()
			elif icon.platformer == IconGamemodeProp.PlatformerState.PLATFORMER_ONLY and (not LevelManager.platformer and speed_multiplier > 0.0):
				icon.hide()
			elif icon.platformer == IconGamemodeProp.PlatformerState.SIDESCROLLER_ONLY and (LevelManager.platformer or speed_multiplier == 0.0):
				icon.hide()
			else:
				icon.show()
@export var internal_gamemode: Gamemode
@export var default_collider: RectangleShape2D
@export var slope_collider: CircleShape2D
@export var spider_animation_tree: AnimationTree

# Public
var dead: bool = false
var coyote_time: float = 0.0
var gameplay_rotation_degrees: float = 0.0
var gameplay_rotation: float:
	get():
		return deg_to_rad(gameplay_rotation_degrees)
	set(value):
		gameplay_rotation_degrees = rad_to_deg(value)
var player_scale: PlayerScale = PlayerScale.NORMAL
var can_hit_ceiling: bool
var jump_hold_disabled: bool
var speed_multiplier: float = 1.0
var gravity_flip: int = 1
var gravity_multiplier: float = 1.0
var horizontal_direction: int = 1
var speed: Vector2:
	get():
		match player_scale:
			PlayerScale.MINI:
				return SPEED_MINI
			PlayerScale.NORMAL:
				return SPEED
			PlayerScale.BIG:
				return SPEED_BIG
			_:
				return SPEED
var dash_control: FireDashComponent = null
var speed_0_portal_control: Interactable = null
var slope_velocity: Vector2
var last_collision: KinematicCollision2D
var floor_angle_history: Array[float]
var floor_angle_average: float
var sprite_floor_angle: float
var dual_index: int
# Allow Ceiling Hit blocks can stack, this avoids their effect being disabled
# in the case of a double collision, which would happen with a bool.
var allow_ceiling_hit_count: int:
	set(value):
		allow_ceiling_hit_count = max(value, 0)
var allow_wave_slide_count: int:
	set(value):
		allow_wave_slide_count = max(value, 0)
var no_auto_checkpoints_count: int:
	set(value):
		no_auto_checkpoints_count = max(value, 0)

# Queues
var orb_queue: Array[OrbInteractable]
var pad_queue: Array[PadInteractable]

# Replay
var replay_physics_tick: int = 0
var replay: Replay = Replay.new()
var in_replay: bool = false

# Private
var _spider_dash_frames: int = 0
var _slope_exit_velocity_frames: int = 0
var _click_buffer_state: ClickBufferState = ClickBufferState.NOT_HOLDING
var _is_flying_gamemode: bool = false
var _wave_rotation_degrees_goal: float = 0.0
var _deferred_velocity_redirect: bool = false
var _spider_state_machine: AnimationNodeStateMachinePlayback = null
var _snap_sprite_rotation: bool = false
var _snap_sprite_rotation_frames: int = 0

@onready var last_automatic_checkpoint_position: Vector2 = position


func _ready() -> void:
	if %DebugOverlays:
		%DebugOverlays.visible = Config.draw_debug_overlays
	$DeathEffect.sprite_frames.clear(&"default")
	for icon in DirAccess.open(Config.icons[PreviewIcon.Icon.DEATH_EFFECT].path).get_files():
		if icon.contains(".import"):
			continue
		var frame := load(Config.icons[PreviewIcon.Icon.DEATH_EFFECT].path + "/" + icon)
		$DeathEffect.sprite_frames.add_frame(&"default", frame)
	%Trail.texture = load(Config.icons[PreviewIcon.Icon.TRAIL].path)
	%Trail.width = %Trail.texture.get_width()
	var empty_frame := Texture2D.new()
	$DeathEffect.sprite_frames.add_frame(&"default", empty_frame)
	$DeathEffect.frame = $DeathEffect.sprite_frames.get_frame_count(&"default") - 1
	platform_on_leave = PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY if not LevelManager.platformer else PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_VELOCITY
	_spider_state_machine = spider_animation_tree["parameters/playback"]
	if dual_index == 0:
		LevelManager.player = self
	else:
		LevelManager.player_duals.append(self)
	_set_particles_visibility.call_deferred()
	if not Editor.in_editor:
		_reset_replay.call_deferred()


func _physics_process(delta: float) -> void:
	if not _should_process():
		return

	# Get velocity
	up_direction = Vector2.UP.rotated(gameplay_rotation) * gravity_flip
	var jump_state: int = _get_jump_state()

	if not in_replay:
		var replay_jump_state: int = int(Input.is_action_pressed(&"jump")) if not Input.is_action_pressed(&"platformer_wave_down") else -1
		replay.data.append(PackedByteArray([replay_jump_state, get_direction()]))

	if in_replay and replay.data.size() > replay_physics_tick:
		_playback_replay()

	velocity = _compute_velocity(delta, velocity, get_direction(), jump_state, $GroundCollider.shape is CircleShape2D)

	# Slope collision resolution
	# Reset collision shape and set it back to the slope collider if needed
	$GroundCollider.shape = default_collider
	$GroundCollider.rotation = gameplay_rotation
	$SolidOverlapCheck/SolidOverlapCheckCollider.shape = default_collider
	last_collision = move_and_collide(speed.y * Vector2.DOWN * delta, true)
	_handle_collision(last_collision, true)

	for i in range(4):
		last_collision = move_and_collide(velocity * delta, true)
		_handle_collision(last_collision, i != 0)
		# Collide down with solids so the wave can crash into them
		if internal_gamemode == Gamemode.WAVE and allow_wave_slide_count == 0:
			last_collision = move_and_collide(speed.y * Vector2.DOWN * delta, true)
			_handle_collision(last_collision, true)

	# Apply movement
	move_and_slide()

	# Sprite updates
	_rotate_sprite_degrees(delta, jump_state)
	%GroundParticles.emitting = is_on_floor() and not is_zero_approx(velocity.rotated(-gameplay_rotation).x) and not dash_control
	if is_on_floor() and not dash_control or displayed_gamemode == Gamemode.WAVE:
		%Trail.add_points = false
	if displayed_gamemode in [Gamemode.SHIP, Gamemode.SWING, Gamemode.UFO]:
		%Trail.add_points = true
	if %Trail.add_points:
		%Trail.material.set_shader_parameter(&"bias", float(%Trail.get_point_count()) / float(%Trail.length) * 1.2)
	match displayed_gamemode:
		Gamemode.SPIDER:
			_update_spider_state_machine(jump_state)
		Gamemode.SWING:
			_update_swing_fire(delta)
	_update_wave_trail(delta)

	# 0x speed portal position nudge
	if speed_0_portal_control:
		var rotation_local_global_position = global_position.rotated(-gameplay_rotation)
		var rotation_local_portal_global_position = speed_0_portal_control.global_position.rotated(-gameplay_rotation)
		var rotation_local_velocity = velocity.rotated(-gameplay_rotation)
		# Update ship icon by running `displayed_gamemode` setter
		displayed_gamemode = displayed_gamemode
		global_position = Vector2(
			rotation_local_global_position.lerp(rotation_local_portal_global_position, 0.3 * delta * 60).x,
			rotation_local_global_position.y,
		).rotated(gameplay_rotation)
		velocity = Vector2(
			0.0,
			rotation_local_velocity.y,
		).rotated(gameplay_rotation)
		if is_equal_approx(rotation_local_global_position.x, rotation_local_portal_global_position.x):
			speed_0_portal_control = null

	if _snap_sprite_rotation:
		if _snap_sprite_rotation_frames > 0:
			_snap_sprite_rotation_frames -= 1
		elif _snap_sprite_rotation_frames == 0:
			_snap_sprite_rotation = false

	if LevelManager.level_playing:
		_handle_checkpoint_placement()
	replay_physics_tick += 1


func reset() -> void:
	show()
	rotation = 0.0
	# Cancel death animation
	$DeathAnimator.stop()
	$DeathParticles.restart()
	$DeathParticles.emitting = false
	$DeathEffect.stop()
	$DeathEffect.frame = $DeathEffect.sprite_frames.get_frame_count(&"default") - 1
	# Reset icon
	for icon_sprite: Node2D in $Icon.get_children():
		icon_sprite.rotation = 0.0
		icon_sprite.scale = Vector2.ONE
	$Icon/Spider/SpiderSprites.rotation = 0.0
	$Icon/Spider/SpiderSprites.scale = Vector2.ONE
	# Reset members
	dead = false
	$Icon.show()
	NodeUtils.free_children(%GroundParticles)
	%GroundParticles.restart()
	%GroundParticles.emitting = false
	gameplay_rotation = 0.0
	velocity = Vector2.ZERO
	player_scale = PlayerScale.NORMAL
	can_hit_ceiling = false
	jump_hold_disabled = false
	speed_multiplier = 1.0
	gravity_flip = 1
	gravity_multiplier = 1.0
	horizontal_direction = 1
	dash_control = null
	speed_0_portal_control = null
	slope_velocity = Vector2.ZERO
	last_collision = null
	floor_angle_history.clear()
	floor_angle_average = 0.0
	sprite_floor_angle = 0.0
	allow_ceiling_hit_count = 0
	allow_wave_slide_count = 0
	no_auto_checkpoints_count = 0
	orb_queue.clear()
	pad_queue.clear()
	replay_physics_tick = 0
	replay = Replay.new()
	in_replay = false
	_spider_dash_frames = 0
	_slope_exit_velocity_frames = 0
	_click_buffer_state = ClickBufferState.NOT_HOLDING
	_is_flying_gamemode = false
	_wave_rotation_degrees_goal = 0.0
	_deferred_velocity_redirect = false
	_snap_sprite_rotation = false
	_snap_sprite_rotation_frames = 0

	update_player_scale(false)
	_set_particles_visibility.call_deferred()
	if not Editor.in_editor:
		_reset_replay.call_deferred()


func defer_snap_sprite_rotation() -> void:
	_snap_sprite_rotation = true
	_snap_sprite_rotation_frames = 16


func update_player_scale(tweened: bool) -> void:
	var player_scale_value: Vector2
	match player_scale:
		PlayerScale.MINI:
			player_scale_value = PLAYER_SCALE_MINI
		PlayerScale.NORMAL:
			player_scale_value = PLAYER_SCALE_NORMAL
		PlayerScale.BIG:
			player_scale_value = PLAYER_SCALE_BIG
	if displayed_gamemode == Gamemode.WAVE:
		player_scale_value *= PLAYER_SCALE_WAVE
	if not tweened:
		scale = player_scale_value
		if not is_node_ready():
			await ready
		%Trail.width = %Trail.texture.get_width() * scale.y
		return
	(
		create_tween() \
		.set_parallel() \
		.tween_property(self, ^"scale", player_scale_value, 0.25) \
		.tween_property(%Trail, ^"width", %Trail.texture.get_width() * scale.y, 0.25) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	)


func place_checkpoint() -> CheckpointPlacementBuilder:
	return CheckpointPlacementBuilder.new(self)


func stop_dash() -> void:
	$DashParticles.emitting = false
	$DashFlame.hide()
	dash_control = null


func get_direction() -> int:
	var direction: int
	if LevelManager.platformer:
		direction = int(Input.get_axis(&"move_left", &"move_right"))
		if direction != 0:
			horizontal_direction = direction
	else:
		direction = horizontal_direction
	return direction


func get_spider_trail_global_position() -> Vector2:
	return $Icon/Spider/SpiderCast/SpiderTrailSpawnPoint.global_position


func _should_process() -> bool:
	return LevelManager.level_playing and not dead


func _handle_collision(collision: KinematicCollision2D, is_refine_iteration: bool) -> void:
	if not collision:
		return
	var collision_angle: float = collision.get_angle(up_direction)
	var is_floor: bool = collision_angle <= deg_to_rad(10.0)
	var is_ceiling: bool = collision_angle >= deg_to_rad(180.0 - 10.0)
	var is_wall: bool = collision_angle > floor_max_angle and collision_angle < PI - floor_max_angle
	var is_slope := not is_floor and not is_ceiling
	if (
		not LevelManager.platformer
		and (
			(is_ceiling and allow_ceiling_hit_count == 0) or is_wall
		)
		or (internal_gamemode == Gamemode.WAVE and allow_wave_slide_count == 0)
	):
		if collision.get_collider().collision_layer & 1 << 1:
			collision.get_collider().collision_layer = 1 << 9
			collision.get_collider().get_node("Hitbox").debug_color.s = 0.0 # DEBUG: Hardcoded name for hitbox color
	if is_ceiling and allow_ceiling_hit_count > 0:
		hit_ceiling.emit(self)
	if is_slope:
		$GroundCollider.shape = slope_collider
		$SolidOverlapCheck/SolidOverlapCheckCollider.shape = slope_collider
	if not is_refine_iteration:
		var level_just_started: bool = LevelManager.current_level and LevelManager.current_level.stopwatch.elapsed_time < get_process_delta_time() * 2.0
		if is_floor and not dash_control and not level_just_started:
			var ground_hit_particles: GPUParticles2D = GROUND_HIT_PARTICLE.instantiate()
			%GroundParticles.add_child(ground_hit_particles)


func _playback_replay() -> void:
	match replay.data[replay_physics_tick][0]:
		1:
			Input.action_press(&"jump")
			Input.action_release(&"platformer_wave_down")
		-1:
			Input.action_press(&"platformer_wave_down")
		_:
			Input.action_release(&"jump")
			Input.action_release(&"platformer_wave_down")
	match replay.data[replay_physics_tick][1]:
		1:
			Input.action_press(&"move_right")
			Input.action_release(&"move_left")
		-1:
			Input.action_press(&"move_left")
			Input.action_release(&"move_right")
		_:
			Input.action_release(&"move_left")
			Input.action_release(&"move_right")


func _reset_replay() -> void:
	if LevelManager.practice_mode:
		return
	replay_physics_tick = 0
	await get_tree().process_frame
	if not in_replay:
		replay.reset()
		replay.level_name = LevelManager.current_level.name
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	Input.action_release(&"platformer_wave_down")


func _get_floor_angle_signed(last_slide: bool, jump_state: int) -> float:
	var floor_normal: Vector2
	if last_slide:
		floor_normal = get_last_slide_collision().get_normal()
	else:
		floor_normal = get_floor_normal()
	var floor_angle: float
	if _is_flying_gamemode and is_on_ceiling() and jump_state == 1:
		var local_up_direction: Vector2 = Vector2.DOWN.rotated(gameplay_rotation) * sign(gravity_flip)
		floor_angle = snappedf(rad_to_deg(floor_normal.angle_to(local_up_direction)), 0.01)
	else:
		floor_angle = snappedf(rad_to_deg(floor_normal.angle_to(up_direction)), 0.01)
	# Iron out jittery angles
	if abs(floor_angle - floor_angle_average) > 0.5:
		floor_angle_history.clear()
	if len(floor_angle_history) > 10:
		floor_angle_history.pop_front()
	floor_angle_history.append(floor_angle)
	floor_angle_average = ArrayUtils.transform(floor_angle_history, ArrayUtils.Transformation.MEAN)
	floor_angle_average = snappedf(floor_angle_average, 0.01)
	if is_equal_approx(abs(floor_angle), 90.0):
		return 0.0
	return deg_to_rad(floor_angle)


func _get_jump_state() -> int:
	var jump_state: int

	if _click_buffer_state == ClickBufferState.NOT_HOLDING and Input.is_action_just_pressed("jump") and not (is_on_floor() or is_on_ceiling()) \
	and internal_gamemode != Gamemode.SHIP and internal_gamemode != Gamemode.SWING and internal_gamemode != Gamemode.WAVE:
		_click_buffer_state = ClickBufferState.BUFFERING
	if _click_buffer_state == ClickBufferState.BUFFERING and not orb_queue.is_empty():
		_click_buffer_state = ClickBufferState.JUMPING
	if Input.is_action_just_released("jump") or ((is_on_floor() or is_on_ceiling()) and not Input.is_action_pressed("jump")):
		_click_buffer_state = ClickBufferState.NOT_HOLDING

	if jump_hold_disabled:
		jump_state = -1
		if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_ceiling() or coyote_time > 0):
			jump_hold_disabled = false
	if jump_hold_disabled:
		return -1
	if internal_gamemode == Gamemode.CUBE:
		jump_state = 1 if Input.is_action_pressed("jump") and (is_on_floor() or coyote_time > 0) else -1
	elif internal_gamemode == Gamemode.ROBOT:
		if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_time > 0):
			$RobotTimer.start(0.25)
		if Input.is_action_just_released("jump"):
			$RobotTimer.stop()
		jump_state = 1 if Input.is_action_pressed("jump") and $RobotTimer.get_time_left() > 0 else -1
	elif internal_gamemode == Gamemode.SHIP or (internal_gamemode == Gamemode.WAVE and not LevelManager.platformer):
		jump_state = 1 if Input.is_action_pressed("jump") else -1
	elif internal_gamemode == Gamemode.WAVE and LevelManager.platformer:
		jump_state = 0
		if Input.is_action_pressed("jump"):
			jump_state = 1
		if Input.is_action_pressed("platformer_wave_down"):
			jump_state = -1
	elif internal_gamemode == Gamemode.UFO or internal_gamemode == Gamemode.SWING:
		jump_state = 1 if Input.is_action_just_pressed("jump") else -1
	elif internal_gamemode == Gamemode.BALL or internal_gamemode == Gamemode.SPIDER:
		jump_state = 1 if (Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_ceiling())) else -1

	if get_viewport().gui_get_hovered_control() != null:
		if get_viewport().gui_get_hovered_control() == Editor.viewport:
			return jump_state
		else:
			return 0 if LevelManager.platformer else -1
	return jump_state


func _compute_velocity(
		delta: float,
		previous_velocity: Vector2,
		direction: int,
		jump_state: int,
		was_sliding_on_slope: bool,
) -> Vector2:
	var local_velocity: Vector2 = previous_velocity.rotated(-gameplay_rotation)
	_is_flying_gamemode = (internal_gamemode == Gamemode.SHIP or internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.WAVE)

	if _spider_dash_frames > 0:
		_spider_dash_frames -= 1

	if _slope_exit_velocity_frames > 0:
		_slope_exit_velocity_frames -= 1

	#region Slope physics
	if was_sliding_on_slope and get_last_slide_collision():
		var floor_angle := _get_floor_angle_signed(true, jump_state)
		# 90° collision warp prevention
		if absf(sin(floor_angle)) < sin(floor_max_angle):
			slope_velocity.y = tan(-floor_angle) * abs(local_velocity.x) * direction
			_slope_exit_velocity_frames = 4
	#endregion

	if (internal_gamemode == Gamemode.SWING or internal_gamemode == Gamemode.BALL) and jump_state == 1 and orb_queue.is_empty():
		gravity_flip *= -1

	$GroundCollider.rotation = gameplay_rotation
	$SolidOverlapCheck.rotation = gameplay_rotation
	$KillColliderSolid.rotation = gameplay_rotation
	$KillColliderRectangularHazard.rotation = gameplay_rotation
	$KillColliderCircularHazard.rotation = gameplay_rotation

	#region Apply Gravity
	if not dash_control:
		if internal_gamemode == Gamemode.SHIP:
			local_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier * jump_state * -1 * FLY_GRAVITY_MULTIPLIER
			local_velocity.y = clamp(local_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif internal_gamemode == Gamemode.SWING:
			local_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier * FLY_GRAVITY_MULTIPLIER
			local_velocity.y = clamp(local_velocity.y, -FLY_TERMINAL_VELOCITY.y, FLY_TERMINAL_VELOCITY.y)
		elif internal_gamemode == Gamemode.WAVE:
			local_velocity.y = SPEED.x * gravity_flip * gravity_multiplier * jump_state * -1
			if speed_multiplier > 0:
				local_velocity.y *= speed_multiplier
			if player_scale == PlayerScale.MINI:
				local_velocity.y *= 2
			elif player_scale == PlayerScale.BIG:
				local_velocity.y *= 0.5
		elif internal_gamemode == Gamemode.SPIDER:
			local_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier * jump_state * -1 * SPIDER_GRAVITY_MULTIPLIER
			local_velocity.y = clamp(local_velocity.y, -TERMINAL_VELOCITY.y, TERMINAL_VELOCITY.y)
		elif not is_on_floor():
			if internal_gamemode == Gamemode.UFO:
				local_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier * UFO_GRAVITY_MULTIPLIER
			else:
				local_velocity.y += GRAVITY * delta * gravity_flip * gravity_multiplier
	#endregion

	var flying_gamemode_slope_boost: bool = _is_flying_gamemode and (
		(is_on_ceiling() and jump_state >= 0) or
		(is_on_floor()
			and get_last_slide_collision() != null
			and _get_floor_angle_signed(true, jump_state) != 0.0
			and get_direction() != 0
			and jump_state == 1 )
	)
	var isnt_jumping: bool = is_on_floor() and jump_state <= 0 and not _deferred_velocity_redirect

	if pad_queue.is_empty() and flying_gamemode_slope_boost or isnt_jumping:
		local_velocity.y = slope_velocity.y

	#region Apply pads velocity
	if not pad_queue.is_empty():
		var colliding_pad: PadInteractable = pad_queue.pop_front()
		local_velocity = _handle_velocity_interactable(local_velocity, colliding_pad, direction)
		%Trail.add_points = true
	#endregion

	#region Handle jump.
	if jump_state == 1 and pad_queue.is_empty() and orb_queue.is_empty():
		if _is_flying_gamemode:
			pass
		elif internal_gamemode == Gamemode.SPIDER:
			var dash_data: PackedFloat64Array = _get_spider_dash_data()
			var dash_height: float = dash_data[0]
			var displacement: Vector2 = Vector2.UP.rotated(gameplay_rotation) * dash_height
			position += displacement
			var trail: SpiderTrail = SPIDER_TRAIL.instantiate()
			trail.start.call_deferred(self, displacement)
			add_child(trail)
			gravity_flip *= -1
			# Force slope collider if needed
			allow_ceiling_hit_count += 1
			# Force up direction update in order for _handle_collision to work properly
			up_direction = Vector2.UP.rotated(gameplay_rotation) * sign(gravity_flip)
			last_collision = move_and_collide(displacement.normalized() * Constants.CELL_SIZE, true)
			$GroundCollider.rotation = gameplay_rotation
			_handle_collision(last_collision, false)
			allow_ceiling_hit_count -= 1
			# Snap velocity to the ground
			var floor_angle: float = dash_data[1]
			local_velocity.y = tan(-floor_angle - gameplay_rotation) * abs(local_velocity.x) * direction
			slope_velocity = Vector2.ZERO
			_spider_dash_frames = 4
			defer_snap_sprite_rotation()
		elif internal_gamemode == Gamemode.BALL:
			local_velocity.y = speed.y * gravity_flip * 0.5
		elif internal_gamemode == Gamemode.ROBOT:
			local_velocity.y = SPEED.x * gravity_flip * -1
		elif internal_gamemode == Gamemode.UFO:
			local_velocity.y = -speed.y * gravity_flip * UFO_GRAVITY_MULTIPLIER
		else:
			local_velocity.y = -speed.y * gravity_flip
	#endregion

	if not LevelManager.platformer or (LevelManager.platformer and internal_gamemode == Gamemode.WAVE):
		if direction:
			local_velocity.x = direction * speed.x * speed_multiplier
		else:
			local_velocity.x = 0
	else:
		if direction:
			local_velocity.x = move_toward(
				local_velocity.x,
				direction * speed.x * speed_multiplier,
				speed.x * delta * speed_multiplier * PLATFORMER_ACCELERATION,
			)
		else:
			local_velocity.x = move_toward(
				local_velocity.x,
				0.0,
				speed.x * delta * speed_multiplier * PLATFORMER_ACCELERATION,
			)

	#region Apply orbs velocity
	if (
		not orb_queue.is_empty()
		and (
			_click_buffer_state == ClickBufferState.JUMPING
			or (jump_state == 1 and not _is_flying_gamemode and not _click_buffer_state == ClickBufferState.BUFFER_USED)
			or (Input.is_action_just_pressed("jump") and _is_flying_gamemode)
		)
	):
		var colliding_orb: OrbInteractable = orb_queue.pop_front()
		_click_buffer_state = ClickBufferState.BUFFER_USED
		colliding_orb.interacted.emit(self)
		local_velocity = _handle_velocity_interactable(local_velocity, colliding_orb, direction)
		if not colliding_orb.has(SingleUsageComponent):
			orb_queue.append(colliding_orb)
		%Trail.add_points = true
	#endregion

	#region Dash orb velocity
	if dash_control:
		local_velocity = dash_control.path.get_velocity(self)
		if Input.is_action_just_released(&"jump"):
			stop_dash()
	#endregion

	var is_falling: bool = local_velocity.y * gravity_flip > 0
	if is_on_floor():
		coyote_time = 2.0 / 60.0
	else:
		if is_falling:
			coyote_time = max(0, coyote_time - delta)
		else:
			coyote_time = 0.0

	_deferred_velocity_redirect = _ensure_velocity_redirect(delta, local_velocity.rotated(gameplay_rotation))

	# Reset slope velocity if needed
	if not is_on_floor() and _slope_exit_velocity_frames == 0:
		slope_velocity = Vector2.ZERO

	return local_velocity.rotated(gameplay_rotation)


func _handle_velocity_interactable(local_velocity: Vector2, interactable: Interactable, direction: int) -> Vector2:
	for component in interactable.components.filter(ArrayUtils.flatten):
		var is_rebound: bool = component is ReboundComponent and (not is_on_floor() or _deferred_velocity_redirect)
		if (
			internal_gamemode != Gamemode.WAVE
			and (component is JumpBoostComponent or is_rebound)
		):
			if internal_gamemode == Gamemode.SPIDER:
				local_velocity.y = component.get_velocity(self) * SPIDER_BOUNCE_MULTIPLIER
			else:
				local_velocity.y = component.get_velocity(self)
			if displayed_gamemode == Gamemode.SPIDER:
				_spider_state_machine.travel("jump")
		elif component is SpiderDashComponent:
			var raycast_rotation: float = interactable.global_rotation
			if gravity_flip < 0:
				raycast_rotation += PI
			$Icon/Spider/SpiderCast.global_rotation = raycast_rotation
			var dash_data: PackedFloat64Array = _get_spider_dash_data()
			var dash_height: float = dash_data[0]
			var floor_angle: float = dash_data[1]
			var displacement: Vector2 = (Vector2.UP * gravity_flip).rotated(interactable.global_rotation) * dash_height
			position += displacement
			jump_hold_disabled = true
			$Icon/Spider/SpiderCast.rotation = 0.0
			var trail_rotation: float = raycast_rotation
			if absf(raycast_rotation) >= PI / 2:
				trail_rotation += PI
			if component.changes_gameplay_rotation():
				if absf(raycast_rotation - gameplay_rotation) <= PI / 4:
					# The teleportation is almost vertical
					gameplay_rotation = raycast_rotation
					gravity_flip *= -1
				else:
					gameplay_rotation = raycast_rotation + PI
					trail_rotation += PI
					gravity_flip = 1
			else:
				gravity_flip = gravity_flip if absf(floor_angle - gameplay_rotation) >= PI / 2 else -gravity_flip
			# Trail
			var trail: SpiderTrail = SPIDER_TRAIL.instantiate()
			add_child(trail)
			trail.start.call_deferred(self, displacement, trail_rotation)
			# Force slope collider if needed
			allow_ceiling_hit_count += 1
			# Force up direction update in order for _handle_collision to work properly
			up_direction = Vector2.UP.rotated(gameplay_rotation) * sign(gravity_flip)
			last_collision = move_and_collide(displacement.normalized() * Constants.CELL_SIZE, true)
			$GroundCollider.rotation = gameplay_rotation
			_handle_collision(last_collision, false)
			allow_ceiling_hit_count -= 1
			_spider_dash_frames = 4
			# Snap velocity to the ground
			local_velocity.y = tan(-floor_angle - gameplay_rotation) * abs(local_velocity.x) * direction
			slope_velocity = Vector2.ZERO
			defer_snap_sprite_rotation()
	return local_velocity


## Ensure velocity redirection can happen and the vertical velocity isn't reset by hitting the floor.
func _ensure_velocity_redirect(delta: float, global_velocity: Vector2) -> bool:
	var down_direction_snapped_velocity := global_velocity.rotated(global_velocity.angle_to(up_direction.rotated(PI)))
	$EnsureVelocityRedirect.shape = $GroundCollider.shape
	$EnsureVelocityRedirect.target_position = down_direction_snapped_velocity * delta * ENSURE_VELOCITY_REDIRECT_SAFE_MARGIN
	$EnsureVelocityRedirect.force_shapecast_update()
	if not $EnsureVelocityRedirect.is_colliding():
		return false
	for i in $EnsureVelocityRedirect.get_collision_count():
		var collided_area := $EnsureVelocityRedirect.get_collider(i) as Area2D
		if not collided_area is Interactable:
			return false
		for component in collided_area.components:
			return (component is ReboundComponent and not is_on_floor()) or (component is TeleportComponent and component.redirect_velocity)
	return false


func _rotate_sprite_degrees(delta: float, jump_state: int):
	var local_velocity := velocity.rotated(-gameplay_rotation)
	var local_velocity_angle_degrees := rad_to_deg(atan2(local_velocity.y * get_direction(), local_velocity.x * get_direction()))
	var dash_horizontal_direction := horizontal_direction if not LevelManager.platformer or dash_control == null else dash_control.initial_horizontal_direction
	if $GroundCollider.shape is CircleShape2D:
		if get_floor_normal() != Vector2.ZERO:
			if not is_zero_approx(_get_floor_angle_signed(false, jump_state)):
				sprite_floor_angle = lerp_angle(
					sprite_floor_angle,
					-_get_floor_angle_signed(false, jump_state) + gameplay_rotation,
					delta * 60 * ICON_LERP_FACTOR,
				)
		elif last_collision != null and last_collision.get_normal() != Vector2.ZERO:
			var collision_angle := -last_collision.get_normal().angle_to(up_direction)
			var ceiling_slide_rotation := PI if collision_angle < 0.0 or abs(collision_angle) > PI / 2 else 0.0
			sprite_floor_angle = lerp_angle(
				sprite_floor_angle,
				-last_collision.get_normal().angle_to(up_direction) + gameplay_rotation + ceiling_slide_rotation,
				delta * 60 * ICON_LERP_FACTOR if not _snap_sprite_rotation else 1.0,
			)
	else:
		sprite_floor_angle = lerp_angle(sprite_floor_angle, gameplay_rotation, delta * 60 * ICON_LERP_FACTOR)

	$GroundParticlesOrigin.scale.y = gravity_flip
	$GroundParticlesOrigin.scale.x = horizontal_direction
	$GroundParticlesOrigin.rotation = sprite_floor_angle

	#region dash
	if dash_control:
		var dash_angle: float = dash_control.path.get_velocity(self).angle()
		var dash_angle_one_sided: float = pingpong(dash_angle - PI / 2, PI) - PI / 2
		var dash_angle_one_sided_wave: float = pingpong(-dash_angle - PI / 2, PI) - PI / 2
		$DashParticles.rotation = dash_angle
		$DashParticles.process_material.angle_min = rad_to_deg(dash_angle)
		$DashParticles.process_material.angle_max = rad_to_deg(dash_angle)
		$DashFlame.rotation = dash_angle
		$Icon/Cube.rotation_degrees += delta * 800 * dash_horizontal_direction * gravity_flip
		$Icon/Ship.rotation = lerpf($Icon/Ship.rotation, dash_angle_one_sided, ICON_LERP_FACTOR * delta * 60)
		$Icon/Swing.rotation = lerpf($Icon/Swing.rotation, dash_angle_one_sided, ICON_LERP_FACTOR * delta * 60)
		$Icon/UFO.rotation = lerpf($Icon/UFO.rotation, dash_angle_one_sided, ICON_LERP_FACTOR * delta * 60)
		$Icon/Jetpack.rotation = lerpf($Icon/UFO.rotation, dash_angle_one_sided, ICON_LERP_FACTOR * delta * 60)
		$Icon/Wave/Icon.rotation = lerpf($Icon/Wave/Icon.rotation, dash_angle_one_sided_wave, ICON_LERP_FACTOR * delta * 60)
		return
	#endregion

	#region cube
	$Icon/Cube.scale.y = 1.0
	if horizontal_direction != 0:
		$Icon/Cube.scale.x = horizontal_direction
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier != 0.0:
			$Icon/Cube.rotation_degrees += delta * gravity_flip * 365 * get_direction() * gravity_multiplier
		else:
			$Icon/Cube.rotation = lerp_angle(
				$Icon/Cube.rotation,
				snapped($Icon/Cube.rotation - sprite_floor_angle, PI / 2) + sprite_floor_angle,
				ICON_LERP_FACTOR * delta * 60 if not _snap_sprite_rotation else 1.0,
			)
	#endregion

	#region ship/swing
	$Icon/Ship.scale.y = sign(gravity_flip)
	$Icon/Ship/ShipParticles.emitting = $Icon/Ship.visible and jump_state > 0
	$Icon/Ship/ShipParticles.interp_to_end = 0.0 if $Icon/Ship.visible else 1.0
	$Icon/Swing.scale.y = 1.0
	$Icon/Ship.scale.x = dash_horizontal_direction
	$Icon/Swing.scale.x = dash_horizontal_direction
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			var target_rotation_degrees := gameplay_rotation_degrees + local_velocity_angle_degrees
			$Icon/Ship.rotation_degrees = lerpf(
				$Icon/Ship.rotation_degrees,
				target_rotation_degrees,
				SHIP_ROTATION_LERP_FACTOR * delta * 60,
			)
			$Icon/Swing.rotation_degrees = lerpf(
				$Icon/Swing.rotation_degrees,
				target_rotation_degrees,
				SHIP_ROTATION_LERP_FACTOR * delta * 60,
			)
		else:
			$Icon/Ship.rotation = lerp_angle($Icon/Ship.rotation, sprite_floor_angle, ICON_LERP_FACTOR * delta * 60 if not _snap_sprite_rotation else 1.0)
			$Icon/Swing.rotation = lerp_angle($Icon/Swing.rotation, sprite_floor_angle, ICON_LERP_FACTOR * delta * 60 if not _snap_sprite_rotation else 1.0)
	#endregion

	#region wave
	$Icon/Wave.rotation = lerpf($Icon/Wave.rotation, gameplay_rotation, ICON_LERP_FACTOR * delta * 60)
	$Icon/Wave.scale.y = 1.0
	if get_direction() != 0 or jump_state != 0:
		_wave_rotation_degrees_goal = rad_to_deg(-pingpong(local_velocity.angle() - PI / 2, PI) + PI / 2)
	$Icon/Wave.scale.x = dash_horizontal_direction
	if not dash_control:
		$Icon/Wave/Icon.rotation_degrees = lerpf(
			$Icon/Wave/Icon.rotation_degrees,
			_wave_rotation_degrees_goal,
			0.25 * delta * 60,
		)
	#endregion

	#region ufo
	$Icon/UFO.scale.y = sign(gravity_flip)
	$Icon/UFO.scale.x = dash_horizontal_direction
	$Icon/Jetpack.scale.y = sign(gravity_flip)
	$Icon/Jetpack.scale.x = dash_horizontal_direction
	$Icon/Jetpack/JetpackParticles.emitting = $Icon/Jetpack.visible and jump_state > 0
	$Icon/Jetpack/JetpackParticles.interp_to_end = 0.0 if $Icon/Jetpack.visible else 1.0
	if not dash_control:
		if not is_on_floor() and not is_on_ceiling() and speed_multiplier > 0.0:
			$Icon/UFO.rotation_degrees = lerpf(
				$Icon/UFO.rotation_degrees,
				velocity.rotated(-gameplay_rotation).y * delta * get_direction() * 0.5 + gameplay_rotation_degrees,
				ICON_LERP_FACTOR * delta * 60,
			)
		else:
			$Icon/UFO.rotation = lerp_angle($Icon/UFO.rotation, sprite_floor_angle, ICON_LERP_FACTOR * delta * 60 if not _snap_sprite_rotation else 1.0)
		$Icon/Jetpack.rotation = lerp_angle(
			$Icon/Jetpack.rotation,
			deg_to_rad(velocity.rotated(-gameplay_rotation).x / speed_multiplier * delta * 5) + sprite_floor_angle,
			ICON_LERP_FACTOR * delta * 60 if not _snap_sprite_rotation else 1.0,
		)
		if jump_state > 0:
			var ufo_particle := UFO_PARTICLE.instantiate()
			$Icon/UFO/UFOParticlesOrigin.add_child(ufo_particle)
	#endregion

	#region ball
	$Icon/Ball.scale.y = 1.0
	if speed_multiplier > 0.0:
		var rotation_delta := delta * 0.45 * gravity_multiplier * (velocity.rotated(-gameplay_rotation).x / speed_multiplier)
		if not dash_control:
			rotation_delta *= gravity_flip
		$Icon/Ball.rotation_degrees += rotation_delta
	if not dash_control:
		var ball_grounded_look_factor = $Icon/Ball.get_meta(&"ball_grounded_look_factor", 0.0)
		if (abs(velocity.rotated(-gameplay_rotation).x) / speed_multiplier) < speed.x * 0.5:
			ball_grounded_look_factor = lerpf(ball_grounded_look_factor, 1.0, 10 * delta)
		else:
			ball_grounded_look_factor = lerpf(ball_grounded_look_factor, 0.0, 10 * delta)
		$Icon/Ball.set_meta(&"ball_grounded_look_factor", ball_grounded_look_factor)
		var ball_rotation_in_air: float = Math.polar_polygon_normalized($Icon/Ball.rotation + deg_to_rad(72.0 / 2.0), 5, 2.0)
		$Icon/Ball.position = Vector2(0.0, lerpf(0.0, lerpf(0, 10, ball_rotation_in_air), ball_grounded_look_factor)).rotated(gameplay_rotation)
	#endregion

	#region spider/robot
	$Icon/Spider.rotation_degrees = gameplay_rotation_degrees
	$Icon/Spider/SpiderSprites.rotation = lerp_angle(
		$Icon/Spider/SpiderSprites.rotation,
		(sprite_floor_angle - gameplay_rotation) * sign(gravity_flip),
		ICON_LERP_FACTOR * delta * 60 if not _snap_sprite_rotation else 1.0,
	)
	$Icon/Robot.rotation = lerp_angle(
		$Icon/Robot.rotation,
		sprite_floor_angle,
		ICON_LERP_FACTOR * delta * 60 if not _snap_sprite_rotation else 1.0,
	)
	if get_direction() != 0:
		$Icon/Spider/SpiderSprites.scale.x = sign(get_direction())
		$Icon/Robot.scale.x = sign(get_direction())
	$Icon/Spider.scale.y = sign(gravity_flip)
	$Icon/Robot.scale.y = sign(gravity_flip)
	#endregion


func _update_swing_fire(delta: float) -> void:
	if displayed_gamemode != Gamemode.SWING:
		$Icon/Swing/FireBoostTop/FireParticles.emitting = false
		$Icon/Swing/FireBoostMiddle/FireParticles.emitting = false
		$Icon/Swing/FireBoostBottom/FireParticles.emitting = false
		$Icon/Swing/FireBoostTop/FireParticles.interp_to_end = 1.0
		$Icon/Swing/FireBoostMiddle/FireParticles.interp_to_end = 1.0
		$Icon/Swing/FireBoostBottom/FireParticles.interp_to_end = 1.0
	else:
		$Icon/Swing/FireBoostMiddle/FireParticles.emitting = true
		$Icon/Swing/FireBoostTop/FireParticles.interp_to_end = 0.0
		$Icon/Swing/FireBoostMiddle/FireParticles.interp_to_end = 0.0
		$Icon/Swing/FireBoostBottom/FireParticles.interp_to_end = 0.0
		if gravity_flip < 0.0:
			$Icon/Swing/FireBoostTop.position = $Icon/Swing/FireBoostTop.position.lerp(Vector2.ZERO, 1 - exp(-delta * 12))
			$Icon/Swing/FireBoostBottom.position = $Icon/Swing/FireBoostBottom.position.lerp(Vector2(-54.0, 63.0), 1 - exp(-delta * 12))
			$Icon/Swing/FireBoostTop/FireParticles.emitting = false
			$Icon/Swing/FireBoostBottom/FireParticles.emitting = true
		else:
			$Icon/Swing/FireBoostTop.position = $Icon/Swing/FireBoostTop.position.lerp(Vector2(-54.0, -63.0), 1 - exp(-delta * 12))
			$Icon/Swing/FireBoostBottom.position = $Icon/Swing/FireBoostBottom.position.lerp(Vector2.ZERO, 1 - exp(-delta * 12))
			$Icon/Swing/FireBoostTop/FireParticles.emitting = true
			$Icon/Swing/FireBoostBottom/FireParticles.emitting = false


func _update_wave_trail(delta: float) -> void:
	var wave_trail_width := WAVE_TRAIL_WIDTH
	var player_camera_zoom_x: float
	player_camera_zoom_x = LevelManager.player_camera.zoom.x if LevelManager.player_camera else 1.0
	if player_scale == PlayerScale.MINI:
		wave_trail_width *= PLAYER_SCALE_MINI.y
	elif player_scale == PlayerScale.BIG:
		wave_trail_width *= PLAYER_SCALE_BIG.y
	%WaveTrail.width = lerpf(%WaveTrail.width, wave_trail_width, 0.25 * delta * 60)
	%WaveTrailInner.width = lerpf(%WaveTrailInner.width, wave_trail_width * 0.5, 0.25 * delta * 60)
	if displayed_gamemode == Gamemode.WAVE:
		%WaveTrail.modulate.a = 1.0
		%WaveTrailInner.modulate.a = 1.0
		%WaveTrail.length = lerpf(%WaveTrail.length, WAVE_TRAIL_LENGTH / player_camera_zoom_x, delta * 60 * 0.2)
		%WaveTrailInner.length = lerpf(%WaveTrail.length, WAVE_TRAIL_LENGTH / player_camera_zoom_x, delta * 60 * 0.2)
	else:
		%WaveTrail.length = 0
		%WaveTrailInner.length = 0
		%WaveTrail.modulate.a = move_toward(%WaveTrail.modulate.a, 0.0, delta * 60 * 0.2)
		%WaveTrailInner.modulate.a = move_toward(%WaveTrailInner.modulate.a, 0.0, delta * 60 * 0.2)
		if is_zero_approx(%WaveTrail.modulate.a):
			%WaveTrail.clear_points()
		if is_zero_approx(%WaveTrailInner.modulate.a):
			%WaveTrailInner.clear_points()


func _set_particles_visibility() -> void:
	var particles_visibility: bool = (
		Config.particles_visibility & Config.ParticleVisibility.PLAYER
		or (Editor.in_editor and not Config.show_particles_in_editor)
	)
	%GroundParticles.visible = particles_visibility
	%ShipParticles.visible = particles_visibility
	%JetpackParticles.visible = particles_visibility
	%UFOParticlesOrigin.visible = particles_visibility
	$DashParticles.visible = particles_visibility
	$DeathParticles.visible = particles_visibility


func _get_spider_dash_data() -> PackedFloat64Array:
	var raycast: RayCast2D = $Icon/Spider/SpiderCast
	raycast.force_raycast_update()
	var target_position = raycast.get_collision_point()
	var dash_height: float = (target_position - position).length()
	var floor_angle: float = raycast.get_collision_normal().angle_to(Vector2.DOWN * gravity_flip)
	var raycast_collision_angle: float = floor_angle + raycast.global_rotation
	dash_height -= (default_collider.size.y * 0.5 * scale.y) / cos(raycast_collision_angle)
	dash_height *= gravity_flip
	if not raycast.is_colliding():
		$DeathAnimator.play("DeathAnimation")
		return [dash_height * 32, floor_angle]
	return [dash_height, floor_angle]


func _update_spider_state_machine(jump_state: int) -> void:
	# `jump` was moved to _compute_velocity to only be triggered with orbs and pads
	# _spider_state_machine.travel("jump")
	if dash_control or (jump_state == -1 and not is_on_floor() and not is_on_ceiling() and not is_on_wall() and not $GroundCollider.shape is CircleShape2D):
		_spider_state_machine.travel(&"fall")
	elif speed_multiplier == 0 or get_direction() == 0:
		_spider_state_machine.travel(&"idle")
	elif speed_multiplier >= 1.849:
		spider_animation_tree["parameters/run/PlayerSpeed/scale"] = speed_multiplier / 1.849
		_spider_state_machine.travel(&"run")
	else:
		spider_animation_tree["parameters/walk/PlayerSpeed/scale"] = speed_multiplier
		_spider_state_machine.travel(&"walk")


func _player_death() -> void:
	#AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), true)
	#dead = true
	#last_automatic_checkpoint_position = position
	#$Icon.hide()
	#$DeathEffect.frame = 0
	#$DeathEffect.play()
	#$DeathParticles.restart()
	#$DashParticles.emitting = false
	#%GroundParticles.emitting = false
	#SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/DeathSound.mp3")
	pass


func _on_death_restart() -> void:
	#LevelManager.game_scene.restart_level()
	pass


func _handle_checkpoint_placement(practice_mode: bool = LevelManager.practice_mode) -> void:
	var checkpoint_parent: Node2D = LevelManager.game_scene.checkpoint_parent
	if not practice_mode:
		return
	if Input.is_action_just_pressed(&"practice_create_checkpoint"):
		place_checkpoint().use_normal_sprite().done()
		last_automatic_checkpoint_position = position
	elif Input.is_action_just_pressed(&"practice_remove_checkpoint"):
		var last_checkpoint: Sprite2D = checkpoint_parent.get_child(-1)
		if not last_checkpoint:
			return
		last_checkpoint.queue_free()
		LevelManager.practice_level_snapshots.pop_back()
	elif Config.automatic_checkpoints and no_auto_checkpoints_count == 0:
		if last_automatic_checkpoint_position.is_finite() and last_automatic_checkpoint_position.distance_to(position) < Config.automatic_checkpoint_distance * Constants.CELL_SIZE:
			return
		if is_on_floor_only():
			place_checkpoint().use_auto_sprite().done()
		elif _is_flying_gamemode or internal_gamemode == Gamemode.UFO:
			place_checkpoint().use_auto_sprite().done()
		else:
			return
		last_automatic_checkpoint_position = position


func _on_kill_collider_solid_body_entered(_body: Node2D) -> void:
	if _spider_dash_frames == 0:
		$DeathAnimator.play("DeathAnimation")


func _on_kill_collider_hazard_area_entered(_area: Area2D) -> void:
	if _spider_dash_frames == 0:
		$DeathAnimator.play("DeathAnimation")


func _on_solid_overlap_check_body_exited(body: Node2D) -> void:
	body = body as CollisionObject2D
	body.collision_layer = 1 << 1
	body.get_node("Hitbox").debug_color = Color("#0012b340") # DEBUG: Hardcoded name for hitbox color
