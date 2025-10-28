extends Node2D
class_name HSVWatcher

enum SelectionHighlight {
	NONE,
	NORMAL,
	DUPLICATE,
}

@export_storage var hsv_shift: Array[float]
@export_storage var strength: float = 1.0
@export_storage var alpha: float = 1.0
# Set by ColorChannelWatchers
@export_storage var base_strength: float = 1.0
@export_storage var base_alpha: float = 1.0

var selection_highlight: SelectionHighlight

@onready var parent: Node2D = get_parent()


func _ready() -> void:
	# Avoid using the parent's modulate if the modulate is already set.
	# This happens when a scene with HSVWatchers with set up modulates is loaded.
	if not parent.has_meta("_has_hsvwatcher"):
		modulate = parent.modulate
	parent.set_meta("_has_hsvwatcher", true)
	hsv_shift.resize(3)


func _process(_delta: float) -> void:
	_update_color.call_deferred()


func serialize() -> Dictionary:
	return {
		"hsv_shift": hsv_shift,
		"strength": strength,
		"alpha": alpha,
	}


func use_data(data: Dictionary) -> void:
	hsv_shift.assign(data.hsv_shift)
	strength = data.strength
	print_debug(strength)
	alpha = data.alpha


func _update_color() -> void:
	var shifted_modulate: Color = modulate
	# FIXME: This field won't change and I can't figure out why.
	#        It works fine when the object has a color channel…
	shifted_modulate.h += hsv_shift[0]
	shifted_modulate.s += hsv_shift[1]
	shifted_modulate.v += hsv_shift[2]
	match selection_highlight:
		SelectionHighlight.NONE:
			parent.modulate = shifted_modulate * strength * base_strength
			parent.modulate.a = modulate.a * alpha * base_alpha
		SelectionHighlight.NORMAL:
			parent.modulate = Color.GREEN
		SelectionHighlight.DUPLICATE:
			parent.modulate = Color.CYAN
