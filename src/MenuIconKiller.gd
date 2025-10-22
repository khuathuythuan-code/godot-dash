extends Area2D
class_name MenuIconKiller

const GRACE_PERIOD: float = 0.05

@export var hitbox: CollisionShape2D


func _ready() -> void:
	if not Config.config.enable_title_screen_icons:
		queue_free()


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		global_position = event.position
		hitbox.disabled = false
		await get_tree().create_timer(GRACE_PERIOD).timeout
		hitbox.disabled = true
	elif event is InputEventMouseButton and event.pressed:
		hitbox.disabled = false
		await get_tree().create_timer(GRACE_PERIOD).timeout
		hitbox.disabled = true
