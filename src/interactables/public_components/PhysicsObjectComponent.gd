extends Node

class_name PhysicsObjectComponent

var physics_object: bool = false
var mass: float = 1.0
var friction: float = 1.0
var rough: bool = false
var bounce: float = 0.0
var absorbent: bool = false
var gravity_scale: float = 1.0


func _ready() -> void:
	LevelManager.level_started.connect(_start)
	update_meta()


func update_meta() -> void:
	var data: Dictionary = {
		"physics_object": physics_object,
		"mass": mass,
		"friction": friction,
		"rough": rough,
		"bounce": bounce,
		"absorbent": absorbent,
		"gravity_scale": gravity_scale,
	}
	get_parent().set_meta("physics", data)


func _start() -> void:
	if not physics_object or get_parent() is RigidBody2D:
		return
	var previous_parent: StaticBody2D = get_parent()
	for child: Node2D in NodeUtils.get_children_of_type(previous_parent, Node2D):
		child.scale *= previous_parent.scale
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
	var nine_patch_sprite_2d_absolute_size: NinePatchSprite2DAbsoluteSize = NodeUtils.get_child_of_type(new_parent, NinePatchSprite2DAbsoluteSize)
	if nine_patch_sprite_2d_absolute_size:
		nine_patch_sprite_2d_absolute_size.parent = new_parent
		nine_patch_sprite_2d_absolute_size.scale = previous_parent.scale
	previous_parent.queue_free()


func use_data(data: Dictionary) -> void:
	physics_object = data.physics_object
	mass = data.mass
	friction = data.friction
	rough = data.rough
	bounce = data.bounce
	absorbent = data.absorbent
	gravity_scale = data.gravity_scale
	update_meta()
