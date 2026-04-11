class_name PhysicsObjectComponent
extends Node

var physics_object: bool = false
var mass: float = 1.0
var friction: float = 1.0
var rough: bool = false
var bounce: float = 0.0
var absorbent: bool = false
var gravity_scale: float = 1.0
var pushable_by_player: bool = true

var linear_velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var scale: Vector2 = Vector2.ONE


func _ready() -> void:
	LevelManager.level_started.connect(_start)
	get_parent().set_meta("physics", true)


func _start() -> void:
	if not physics_object or get_parent() is RigidBody2D:
		return
	var previous_parent: StaticBody2D = get_parent()
	if previous_parent.scale != Vector2.ONE:
		scale = previous_parent.scale
	for child: Node2D in NodeUtils.get_children_of_type(previous_parent, Node2D):
		child.scale *= scale
	var new_parent: RigidBody2D = RigidBody2D.new()
	new_parent.name = previous_parent.name
	for child in previous_parent.get_children():
		if child is Attribute and child.get_property_list().has("parent"):
			child.parent = new_parent
			child.call_deferred("_ready")
	new_parent.set_meta("physics", true)
	new_parent.transform = previous_parent.transform
	new_parent.collision_mask = 2103
	if not pushable_by_player:
		new_parent.collision_layer = 2
	new_parent.mass = mass
	new_parent.physics_material_override = PhysicsMaterial.new()
	new_parent.physics_material_override.friction = friction
	new_parent.physics_material_override.rough = rough
	new_parent.physics_material_override.bounce = bounce
	new_parent.physics_material_override.absorbent = absorbent
	new_parent.gravity_scale = gravity_scale
	new_parent.linear_velocity = linear_velocity
	new_parent.angular_velocity = angular_velocity
	for group in previous_parent.get_groups():
		new_parent.add_to_group(group)
	previous_parent.replace_by(new_parent)
	var nine_patch_sprite_2d_absolute_size: NinePatchSprite2DAbsoluteSize = NodeUtils.get_child_of_type(new_parent, NinePatchSprite2DAbsoluteSize)
	if nine_patch_sprite_2d_absolute_size:
		nine_patch_sprite_2d_absolute_size.parent = new_parent
		nine_patch_sprite_2d_absolute_size.scale = scale
	previous_parent.queue_free()


func get_data() -> Dictionary:
	var data: Dictionary = {
		"physics_object": physics_object,
		"mass": mass,
		"friction": friction,
		"rough": rough,
		"bounce": bounce,
		"absorbent": absorbent,
		"gravity_scale": gravity_scale,
		"pushable_by_player": pushable_by_player,
		"linear_velocity": Serialize.Vector2(get_parent().linear_velocity) if get_parent() is RigidBody2D else Serialize.Vector2(linear_velocity),
		"angular_velocity": get_parent().angular_velocity if get_parent() is RigidBody2D else angular_velocity,
		"scale": Serialize.Vector2(get_parent().scale) if get_parent() is StaticBody2D else Serialize.Vector2(scale),
	}
	return data


func use_data(data: Dictionary) -> void:
	physics_object = data.physics_object
	mass = data.mass
	friction = data.friction
	rough = data.rough
	bounce = data.bounce
	absorbent = data.absorbent
	gravity_scale = data.gravity_scale
	pushable_by_player = data.pushable_by_player
	linear_velocity = Deserialize.Vector2(data.linear_velocity)
	angular_velocity = data.angular_velocity
	scale = Deserialize.Vector2(data.scale)
