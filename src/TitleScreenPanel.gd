class_name TitleScreenPanel
extends PanelContainer

var tween: Tween
@onready var inital_position: Vector2 = position


func _ready() -> void:
	position.x = get_viewport().get_visible_rect().size.x


func show_tween() -> void:
	top_level = true
	show()
	if tween:
		tween.stop()
	tween = create_tween()
	(
		tween \
		.tween_property(self, ^"position:x", inital_position.x, Config.transition_duration) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUINT)
	)
	await tween.finished
	top_level = false


func hide_tween() -> void:
	if tween:
		tween.stop()
	tween = create_tween()
	(
		tween \
		.tween_property(self, ^"position:x", get_viewport().get_visible_rect().size.x, Config.transition_duration) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUINT)
	)
	await tween.finished
	hide()
