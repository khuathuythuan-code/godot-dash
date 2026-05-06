class_name LevelCheckpointComponent
extends Component

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer


func _ready() -> void:
	sprite.set_instance_shader_parameter(&"enabled_factor", 0.0)
	sprite.set_instance_shader_parameter(&"hue", 2.0 / 3.0)
	parent.interacted.connect(place_checkpoint)


func place_checkpoint(player: Player) -> void:
	sprite.set_instance_shader_parameter(&"enabled_factor", 1.0)
	var player_just_respawned: bool = LevelManager.current_level.stopwatch.elapsed_time < get_process_delta_time()
	if player_just_respawned:
		return
	var tween: Tween = create_tween()
	(
		tween.tween_method(
			_set_sprite_enabled_factor,
			1.0, # from
			0.0, # to
			0.75, # duration
		) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_EXPO)
	)
	animation_player.play(&"Activate")
	player.place_checkpoint().done()


func _set_sprite_enabled_factor(factor: float) -> void:
	sprite.set_instance_shader_parameter(&"flash_factor", factor)
