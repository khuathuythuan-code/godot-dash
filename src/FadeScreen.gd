extends CanvasLayer

class_name FadeScreen

signal fade_finished

var is_fading: bool

enum FadeType {
	FADE_IN,
	FADE_OUT,
}


func _ready() -> void:
	$ColorRect.color = Color.BLACK
	hide()


func fade_in(fade_duration: float, ease_type: Tween.EaseType = Tween.EASE_IN_OUT, trans_type: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	is_fading = true
	show()
	var fade_tween = get_tree().create_tween()
	(
		fade_tween \
		.tween_property($ColorRect, ^"color", Color.BLACK, fade_duration) \
		.set_ease(ease_type) \
		.set_trans(trans_type) \
		.from(Color.hex(0x00000000)) # transparent black
	)
	await fade_tween.finished
	fade_finished.emit(FadeType.FADE_IN)
	is_fading = false


func fade_out(fade_duration: float, ease_type: Tween.EaseType, trans_type: Tween.TransitionType) -> void:
	is_fading = true
	show()
	var fade_tween = get_tree().create_tween()
	(
		fade_tween \
		.tween_property($ColorRect, ^"color", Color.hex(0x00000000), fade_duration) \
		.set_ease(ease_type) \
		.set_trans(trans_type) \
		.from(Color.BLACK)
	)
	await fade_tween.finished
	fade_finished.emit(FadeType.FADE_OUT)
	hide()
	is_fading = false


func anticipate_fade_out() -> void:
	$ColorRect.color = Color.BLACK
	show()
