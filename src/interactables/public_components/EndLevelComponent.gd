class_name EndLevelComponent
extends Component

const TRANSITION_DURATION := 1.0

# No registration since we don't want these fields to appear in the editor
@export var static_trigger: TriggerInteractable
@export var shake_trigger: TriggerInteractable

var initial_player_positions: Dictionary[Player, Vector2]


func _ready() -> void:
	add_to_group("end_level")
	await require([TargetObjectComponent])
	var static_easing: EasingComponent = static_trigger.query(EasingComponent)
	var shake_camera_shake: CameraShakeComponent = shake_trigger.query(CameraShakeComponent)
	var shake_easing: EasingComponent = shake_trigger.query(EasingComponent)
	static_easing.easing_type = Tween.EASE_IN
	static_easing.easing_transition = Tween.TRANS_EXPO
	static_easing.progressed.connect(_on_static_easing_progressed)
	static_easing.finished.connect(_on_static_easing_finished)
	shake_camera_shake.strength = 25.0
	shake_easing.duration = 2.0
	shake_easing.easing_type = Tween.EASE_IN
	shake_easing.easing_transition = Tween.TRANS_QUAD
	shake_easing.finished.connect(_on_shake_easing_finished)
	parent.interacted.connect(start)


func start(player: Player) -> void:
	if parent.query(TargetObjectComponent).target.is_empty():
		Toasts.error("In %s: target object is unset" % parent.name)
		return
	player.normal_trail.clear_points()
	var static_target: TargetObjectComponent = static_trigger.query(TargetObjectComponent)
	static_target.target = parent.query(TargetObjectComponent).target
	static_trigger.interacted.emit(player)
	# Disable player collision
	player.process_mode = Node.PROCESS_MODE_DISABLED
	initial_player_positions.set(player, player.global_position)
	LevelManager.current_level.stop_timer()
	LevelManager.player_camera.freefly = true


# We use the static trigger's easing instead of requiring one,
# so it doesn't appear in the UI and it avoids duplication.
func _on_static_easing_progressed(player: Player, weight_delta: float) -> void:
	var initial_player_position := initial_player_positions[player]
	var target: Node2D = parent.query(TargetObjectComponent).target_to_node()
	var weight: float = static_trigger.query(EasingComponent).weights[player]
	var rotation_direction = 1 if player.global_position < target.global_position else -1
	player.global_position = initial_player_position.lerp(target.global_position, weight)
	player.rotation += weight_delta * 5 * rotation_direction
	$"../CPUParticles2D".global_position = target.global_position


func _on_static_easing_finished(player: Player) -> void:
	shake_trigger.interacted.emit(player)
	player.hide()
	#$"../HiddenOutsideEditorAttribute" ẩn sprite của EndLevelTrigger khi chạy game
	#trong .json của level, 
	#block nào có "attributes": ["HiddenOutsideEditorAttribute.gd"] thì chỉ hiện trong editor 
	$"..".show()
	$"../Sprite".hide()
	$"../CPUParticles2D".show()
	

func _on_shake_easing_finished(_player: Player) -> void:
	LevelManager.current_level.stop_level()
	var end_level_menu = LevelManager.game_scene.level_complete_menu
	end_level_menu._show()
	var new_time = end_level_menu.stat_controller.time_elapsed
	var new_jump = end_level_menu.stat_controller.jump_count
	var new_attempt = LevelManager.game_scene.pause_menu.attempt_count
	var level_name = LevelManager.current_level_name
	var new_completion: float = 100.0
	SaveManager.update_and_save_best_record(level_name, new_completion, new_attempt,new_time,new_jump)
