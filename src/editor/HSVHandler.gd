class_name HSVHandler
extends Node

@export var hue: FloatSliderProperty
@export var saturation: FloatSliderProperty
@export var value: FloatSliderProperty
@export var intensity: FloatSliderProperty
@export var alpha: FloatSliderProperty

var hsv_watchers: Array[HSVWatcher]
var selected_object_count: int


func _ready() -> void:
	var connections: Dictionary[FloatSliderProperty, Callable]
	connections.assign(
		{
			hue: set_hue,
			saturation: set_saturation,
			value: set_value,
			intensity: set_intensity,
			alpha: set_alpha,
		},
	)
	for property: FloatSliderProperty in connections:
		property.interaction_ended.connect(_on_property_interaction_ended.bind(property, connections[property]))


func _on_edit_handler_selection_changed(selection: Selection) -> void:
	selected_object_count = selection.size()
	if selection.is_empty():
		hsv_watchers.clear()
		return
	hsv_watchers.assign(
		selection \
		.map_generic(BaseDetailHandler.into_base) \
		.map(BaseDetailHandler.use_hsv_watcher),
	)
	hsv_watchers.append_array(
		selection.map_generic(func(object: Node2D): return object.get_node_or_null(^"Detail")) \
		.filter(ArrayUtils.flatten) \
		.map(BaseDetailHandler.use_hsv_watcher),
	)
	var last_hsv_watcher: HSVWatcher = hsv_watchers[-1]
	hue.set_value_no_signal(last_hsv_watcher.hsv_shift[0])
	saturation.set_value_no_signal(last_hsv_watcher.hsv_shift[1])
	value.set_value_no_signal(last_hsv_watcher.hsv_shift[2])
	intensity.set_value_no_signal(last_hsv_watcher.intensity)
	alpha.set_value_no_signal(last_hsv_watcher.alpha)


func set_hue(_hsv_watchers: Array[HSVWatcher], new_hue: float) -> void:
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.hsv_shift[0] = new_hue)
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.update_color())


func set_saturation(_hsv_watchers: Array[HSVWatcher], new_saturation: float) -> void:
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.hsv_shift[1] = new_saturation)
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.update_color())


func set_value(_hsv_watchers: Array[HSVWatcher], new_value: float) -> void:
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.hsv_shift[2] = new_value)
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.update_color())


func set_intensity(_hsv_watchers: Array[HSVWatcher], new_intensity: float) -> void:
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.intensity = new_intensity)
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.update_color())


func set_alpha(_hsv_watchers: Array[HSVWatcher], new_alpha: float) -> void:
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.alpha = new_alpha)
	_hsv_watchers.map(func(hsv_watcher: HSVWatcher): hsv_watcher.update_color())


func _on_hue_value_changed(new_value: float) -> void:
	set_hue(hsv_watchers, new_value)


func _on_saturation_value_changed(new_value: float) -> void:
	set_saturation(hsv_watchers, new_value)


func _on_value_value_changed(new_value: float) -> void:
	set_value(hsv_watchers, new_value)


func _on_intensity_value_changed(new_value: float) -> void:
	set_intensity(hsv_watchers, new_value)


func _on_alpha_value_changed(new_value: float) -> void:
	set_alpha(hsv_watchers, new_value)


func _on_property_interaction_ended(new_value: float, previous_value: float, property: FloatSliderProperty, action: Callable) -> void:
	var set_property := func(_value: float):
		action.call(hsv_watchers.duplicate(), _value)
		property.set_value_no_signal(_value)
	var version_history: UndoRedo = Editor.version_history
	version_history.create_action("Changed %s on %s objects" % [property.name.capitalize().to_lower(), selected_object_count])
	version_history.add_do_method(set_property.bind(new_value))
	version_history.add_undo_method(set_property.bind(previous_value))
	version_history.commit_action()
