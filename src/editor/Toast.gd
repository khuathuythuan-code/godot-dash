class_name Toast
extends Button

var lifetime: float
var persistent: bool


func _ready() -> void:
	if not persistent:
		$Timer.start(lifetime)
		$Timer.timeout.connect(dismiss)


func update_text(new_text: String) -> void:
	text = new_text


func dismiss() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, ^"modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
