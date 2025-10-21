extends Area2D
class_name MenuIconKiller

@export var hitbox: CollisionShape2D
var grace_period: float = 0.05


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		global_position = event.position
		hitbox.disabled = false
		await get_tree().create_timer(grace_period).timeout
		hitbox.disabled = true
	elif event is InputEventMouseButton and event.pressed:
		hitbox.disabled = false
		await get_tree().create_timer(grace_period).timeout
		hitbox.disabled = true
