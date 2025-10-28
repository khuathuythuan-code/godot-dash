@tool
extends BaseButton
class_name BouncyButton

# @export var selected_level: PackedScene
@export var block_palette_button: bool
@export var reset_scale_on_ready: bool = false
var saved_position: Vector2
var absolute_position: Vector2

func _ready() -> void:
	if reset_scale_on_ready:
		scale = Vector2.ONE
	connect("button_down", Callable(self, "_button_held"))
	connect("button_up", Callable(self, "_button_unheld"))

func _process(_delta: float) -> void:
	pivot_offset.x = size.x/2
	pivot_offset.y = size.y/2
	if block_palette_button:
		if is_pressed():
			modulate = Color("808080")
		else:
			modulate = Color("ffffff")

func _button_held() -> void:
	if is_inside_tree():
		var scale_tween = create_tween()
		scale_tween.set_ease(Tween.EASE_OUT)
		scale_tween.set_trans(Tween.TRANS_BOUNCE)
		scale_tween.tween_property(self, "scale", scale * 1.1, 0.2)
		if get_parent() is Container:
			if not top_level:
				saved_position = position
				position = get_global_rect().position
			top_level = true

func _button_unheld() -> void:
	if is_inside_tree():
		var scale_tween = create_tween()
		scale_tween.set_ease(Tween.EASE_OUT)
		scale_tween.set_trans(Tween.TRANS_BOUNCE)
		scale_tween.tween_property(self, "scale", scale / 1.1, 0.2)
		release_focus()
		await scale_tween.finished
		if get_parent() is Container:
			top_level = false
			position = saved_position
