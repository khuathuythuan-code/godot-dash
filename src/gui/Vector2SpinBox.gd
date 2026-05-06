@tool
class_name Vector2SpinBox
extends BoxContainer

signal value_changed(new_value: Vector2)
signal interaction_ended(value: Vector2, previous: Vector2)

@export var keep_aspect: bool
@export var rounded: bool
@export var step: float
@export var min_value: float
@export var max_value: float
@export var allow_greater: bool
@export var allow_lesser: bool
@export var prefix: String:
	set = _set_prefix
@export var suffix: String:
	set(value):
		suffix = value
		if not is_node_ready():
			return
		for spinbox in [spinbox_x, spinbox_y]:
			spinbox.suffix = value
@export var select_all_on_focus: bool
@export var editable: bool:
	set(value):
		editable = value
		if not is_node_ready():
			return
		for spinbox in [spinbox_x, spinbox_y]:
			spinbox.editable = value
@export var expand_to_text_length: bool

var aspect_ratio: float

var _value: Vector2 = Vector2.ZERO

@onready var spinbox_x: SpinBox
@onready var spinbox_y: SpinBox


func _ready() -> void:
	spinbox_x = NodeUtils.get_node_or_add(self, "SpinBoxX", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	spinbox_y = NodeUtils.get_node_or_add(self, "SpinBoxY", SpinBox, NodeUtils.INTERNAL | NodeUtils.SET_OWNER)
	spinbox_x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox_y.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox_x.value_changed.connect(_set_x)
	spinbox_y.value_changed.connect(_set_y)
	update_internals()
	set_value(_value)


func update_internals() -> void:
	if keep_aspect:
		aspect_ratio = get_viewport_rect().size.aspect()
	for spinbox: SpinBox in [spinbox_x, spinbox_y]:
		spinbox.alignment = HORIZONTAL_ALIGNMENT_FILL
		spinbox.min_value = min_value
		spinbox.max_value = max_value
		spinbox.allow_greater = allow_greater
		spinbox.allow_lesser = allow_lesser
		spinbox.suffix = suffix
		spinbox.step = step
		spinbox.custom_minimum_size.x = 128
		spinbox.rounded = rounded
		spinbox.select_all_on_focus = select_all_on_focus
		spinbox.get_line_edit().expand_to_text_length = expand_to_text_length
	_set_prefix(prefix)


func set_value(new_value: Vector2) -> void:
	var previous: Vector2 = _value
	set_value_no_signal(new_value)
	value_changed.emit(_value)
	interaction_ended.emit(_value, previous)


func set_value_no_signal(new_value: Vector2):
	_value = new_value
	spinbox_x.set_value_no_signal(new_value.x)
	spinbox_y.set_value_no_signal(new_value.y)


func _set_x(new_value: float) -> void:
	var previous: Vector2 = _value
	_value.x = new_value
	if keep_aspect:
		_value.y = new_value * 1 / aspect_ratio
		spinbox_y.set_value_no_signal(_value.y)
	value_changed.emit(_value)
	interaction_ended.emit(_value, previous)


func _set_y(new_value: float) -> void:
	var previous: Vector2 = _value
	_value.y = new_value
	if keep_aspect:
		_value.x = new_value * aspect_ratio
		spinbox_x.set_value_no_signal(_value.x)
	value_changed.emit(_value)
	interaction_ended.emit(_value, previous)


func get_value() -> Vector2:
	return _value


func _set_prefix(new_prefix: String) -> void:
	if spinbox_x == null or spinbox_y == null:
		return
	prefix = new_prefix
	if new_prefix != "":
		for spinbox in [spinbox_x, spinbox_y]:
			spinbox.prefix = _value
	else:
		spinbox_x.prefix = "x:"
		spinbox_y.prefix = "y:"
