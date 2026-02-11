extends Builder

class_name CheckpointPlacementBuilder

const CHECKPOINT_TEXTURE: Texture2D = preload("uid://byhliui13khoi")
const AUTOMATIC_CHECKPOINT_TEXTURE: Texture2D = preload("uid://dcqatki40lxp4")

var player: Player
var new_checkpoint: Sprite2D


func _init(new_player: Player) -> void:
	player = new_player


func use_normal_sprite() -> CheckpointPlacementBuilder:
	new_checkpoint = Sprite2D.new()
	new_checkpoint.texture = CHECKPOINT_TEXTURE
	return self


func use_auto_sprite() -> CheckpointPlacementBuilder:
	new_checkpoint = Sprite2D.new()
	new_checkpoint.texture = AUTOMATIC_CHECKPOINT_TEXTURE
	return self


func done() -> void:
	if new_checkpoint:
		var checkpoint_parent: Node2D = LevelManager.game_scene.checkpoint_parent
		checkpoint_parent.add_child(new_checkpoint)
		new_checkpoint.name = "Checkpoint%s" % checkpoint_parent.get_child_count()
		new_checkpoint.global_position = player.global_position
		new_checkpoint.global_rotation_degrees = player.gameplay_rotation_degrees
	LevelManager.practice_level_snapshots.append(
		LevelManager.current_level.to_data(Level.SerializeReason.PRACTICE_ATTEMPT),
	)
