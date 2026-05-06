@tool
class_name BouncyButton
extends BaseButton

# @export var selected_level: PackedScene
@export var block_palette_button: bool
@export var reset_scale_on_ready: bool = false
var saved_position: Vector2
var absolute_position: Vector2
var inital_scale: Vector2


func _ready() -> void:
	if reset_scale_on_ready:
		scale = Vector2.ONE
	inital_scale = scale
	button_down.connect(_button_held)
	button_up.connect(_button_unheld)


func _process(_delta: float) -> void:
	pivot_offset_ratio = Vector2.ONE * 0.5
	if not block_palette_button:
		return
	modulate = Color.hex(0x808080ff) if is_pressed() else Color.WHITE


func _button_held() -> void:
	if not is_inside_tree():
		return
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_BOUNCE)
	scale_tween.tween_property(self, ^"scale", inital_scale * 1.1, 0.2)
	if get_parent() is not Container:
		return
	if not top_level:
		saved_position = position
		position = get_global_rect().position
	top_level = true


func _button_unheld() -> void:
	if not is_inside_tree():
		return
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_BOUNCE)
	scale_tween.tween_property(self, ^"scale", inital_scale, 0.2)
	release_focus()
	await scale_tween.finished
	if get_parent() is not Container:
		return
	top_level = false
	position = saved_position
