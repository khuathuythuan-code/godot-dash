extends VBoxContainer

class_name PhysicsEditor

@onready var parent: Node = get_parent()

@export var physics_object_property: BoolProperty
@export var mass_property: FloatProperty
@export var friction_property: FloatProperty
@export var rough_property: BoolProperty
@export var bounce_property: FloatProperty
@export var absorbent_property: BoolProperty
@export var gravity_scale_property: FloatProperty

var solid_objects: Selection = Selection.new()


func _on_edit_handler_selection_changed(_selection: Selection) -> void:
	solid_objects = _selection.filter(func(object): return object.has_meta(&"physics"))
	if solid_objects.is_empty():
		get_parent().hide()
		return
	get_parent().show()
	var data: Dictionary = solid_objects.first().get_meta(&"physics")
	physics_object_property.set_value_no_signal(data.physics_object)
	mass_property.set_value_no_signal(data.mass)
	friction_property.set_value_no_signal(data.friction)
	rough_property.set_value_no_signal(data.rough)
	bounce_property.set_value_no_signal(data.bounce)
	absorbent_property.set_value_no_signal(data.absorbent)
	gravity_scale_property.set_value_no_signal(data.gravity_scale)


func _on_physics_object_value_changed(value: bool) -> void:
	if solid_objects.is_empty():
		return
	solid_objects.for_each(
		func(object: Object):
			var component: PhysicsObjectComponent = NodeUtils.get_child_of_type(object, PhysicsObjectComponent)
			component.physics_object = value
			component.update_meta()
	)


func _on_mass_value_changed(value: float) -> void:
	if solid_objects.is_empty():
		return
	solid_objects.for_each(
		func(object: Object):
			var component: PhysicsObjectComponent = NodeUtils.get_child_of_type(object, PhysicsObjectComponent)
			component.mass = value
			component.update_meta()
	)


func _on_friction_value_changed(value: float) -> void:
	if solid_objects.is_empty():
		return
	solid_objects.for_each(
		func(object: Object):
			var component: PhysicsObjectComponent = NodeUtils.get_child_of_type(object, PhysicsObjectComponent)
			component.friction = value
			component.update_meta()
	)


func _on_rough_value_changed(value: bool) -> void:
	if solid_objects.is_empty():
		return
	solid_objects.for_each(
		func(object: Object):
			var component: PhysicsObjectComponent = NodeUtils.get_child_of_type(object, PhysicsObjectComponent)
			component.rough = value
			component.update_meta()
	)


func _on_bounce_value_changed(value: float) -> void:
	if solid_objects.is_empty():
		return
	solid_objects.for_each(
		func(object: Object):
			var component: PhysicsObjectComponent = NodeUtils.get_child_of_type(object, PhysicsObjectComponent)
			component.bounce = value
			component.update_meta()
	)


func _on_absorbent_value_changed(value: bool) -> void:
	if solid_objects.is_empty():
		return
	solid_objects.for_each(
		func(object: Object):
			var component: PhysicsObjectComponent = NodeUtils.get_child_of_type(object, PhysicsObjectComponent)
			component.absorbent = value
			component.update_meta()
	)


func _on_gravity_scale_value_changed(value: float) -> void:
	if solid_objects.is_empty():
		return
	solid_objects.for_each(
		func(object: Object):
			var component: PhysicsObjectComponent = NodeUtils.get_child_of_type(object, PhysicsObjectComponent)
			component.gravity_scale = value
			component.update_meta()
	)
