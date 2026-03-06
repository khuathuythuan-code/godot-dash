extends Node

class_name PhysicsObjectComponent

@export var physics_object: bool = false
@export var mass: float = 1.0
@export var friction: float = 1.0
@export var rough: bool = false
@export var bounce: float = 0.0
@export var absorbent: bool = false
@export var gravity_scale: float = 1.0

func _ready() -> void:
	LevelManager.level_started.connect(_start)


func _start() -> void:
	if not physics_object or get_parent() is RigidBody2D:
		return
	var previous_parent: StaticBody2D = get_parent()
	var new_parent: RigidBody2D = RigidBody2D.new()
	new_parent.transform = previous_parent.transform
	new_parent.collision_mask = 2103
	new_parent.mass = mass
	new_parent.physics_material_override = PhysicsMaterial.new()
	new_parent.physics_material_override.friction = friction
	new_parent.physics_material_override.rough = rough
	new_parent.physics_material_override.bounce = bounce
	new_parent.physics_material_override.absorbent = absorbent
	new_parent.gravity_scale = gravity_scale
	previous_parent.replace_by(new_parent)
	previous_parent.queue_free()
	var nine_patch_sprite_2d_absolute_size: NinePatchSprite2DAbsoluteSize = NodeUtils.get_child_of_type(new_parent, NinePatchSprite2DAbsoluteSize)
	if nine_patch_sprite_2d_absolute_size:
		nine_patch_sprite_2d_absolute_size.parent = new_parent
