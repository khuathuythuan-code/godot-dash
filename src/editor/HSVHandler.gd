extends Node
class_name HSVHandler


@export var hue: FloatSliderProperty
@export var saturation: FloatSliderProperty
@export var value: FloatSliderProperty
@export var strength: FloatSliderProperty
@export var alpha: FloatSliderProperty
@export var editor_viewport: Control


func _has_hsv_watcher(object) -> bool:
	return object.has_node("HSVWatcher")


func _on_hue_value_changed(new_value: float) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node(^"HSVWatcher").hsv_shift[0] = new_value)


func _on_saturation_value_changed(new_value: float) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node(^"HSVWatcher").hsv_shift[1] = new_value)


func _on_value_value_changed(new_value: float) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node(^"HSVWatcher").hsv_shift[2] = new_value)


func _on_strength_value_changed(new_value: float) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node(^"HSVWatcher").strength = new_value)


func _on_alpha_value_changed(new_value: float) -> void:
	$"../EditHandler".selection.filter(_has_hsv_watcher).map(func(object): object.get_node(^"HSVWatcher").alpha = new_value)


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	var objects_with_hsv_watcher: Array[Node2D] = selection.filter(_has_hsv_watcher)
	if objects_with_hsv_watcher.is_empty():
		for property in [hue, saturation, value]:
			property.set_value_no_signal(0.0)
		strength.set_value_no_signal(1.0)
		alpha.set_value_no_signal(1.0)
	else:
		var last_hsv_watcher = BaseDetailHandler.use_hsv_watcher(objects_with_hsv_watcher.back())
		hue.set_value_no_signal(last_hsv_watcher.hsv_shift[0])
		saturation.set_value_no_signal(last_hsv_watcher.hsv_shift[1])
		value.set_value_no_signal(last_hsv_watcher.hsv_shift[2])
		strength.set_value_no_signal(last_hsv_watcher.strength)
		alpha.set_value_no_signal(last_hsv_watcher.alpha)
