@abstract
extends Control
class_name Gizmo

enum State {
	DISABLED,
	ENABLED,
	FORCED,
}

var quick_gizmo_value_input: QuickGizmoValueInput
var gizmo_scale: float
var state: State

var _quick: bool


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		remove_gizmo(true)
	if event.is_action_pressed(&"ui_accept"):
		remove_gizmo(false)


func quick(keychord_display: Label, prefix: String, suffix: String) -> void:
	_quick = true
	quick_gizmo_value_input = QuickGizmoValueInput.new(keychord_display, prefix, suffix, true)
	state = State.FORCED


@abstract func remove_gizmo(reset: bool = false) -> void

@abstract func is_enabled() -> bool

@abstract func any_handle_hovered() -> bool
