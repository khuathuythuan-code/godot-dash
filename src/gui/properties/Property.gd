@abstract
extends BoxContainer
class_name Property


# Used to serialize the value
var _value: Variant
var label: Label

func _init() -> void:
	custom_minimum_size.y = 32.0

@abstract func reset() -> void

@abstract func refresh() -> void

@abstract func set_input_state(enabled: bool) -> void


func submitted_release_focus(_new_value):
	get_viewport().gui_release_focus()


func unedit_release_focus(toggled_on):
	if not toggled_on:
		get_viewport().gui_release_focus()
