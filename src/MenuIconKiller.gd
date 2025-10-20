extends StaticBody2D
class_name MenuIconKiller

@onready var hitbox: CollisionShape2D = get_child(0)
var grace_period: float = 0.05

func _ready() -> void:
	if !Config.config.enable_easter_eggs:
		queue_free()

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
