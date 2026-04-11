class_name GameplayRotateTriggerSprite
extends TriggerSprite

@export var gameplay_rotation_changer_component: GameplayRotationChangerComponent
@export var direction_changer_component: DirectionChangerComponent


func _process(_delta: float) -> void:
	if not visible:
		return
	global_rotation_degrees = gameplay_rotation_changer_component.gameplay_rotation
	flip_h = direction_changer_component.direction == DirectionChangerComponent.Direction.BACKWARDS
