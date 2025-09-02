extends Component
class_name TargetObjectComponent

signal target_changed(new_target: Node2D)

@export var target: Node2D:
	set(value):
		target = value
		if override == null:
			_override_saved_value = value
		target_changed.emit(value)

## Override the target to another one defined in code.
## Used by [CameraStaticComponent] to force the target
## to be [LevelManager.player] when its mode is set to
## [CameraStaticComponent.Mode.EXIT].
var override: Node2D:
	set(value):
		if override != value:
			override = value
			notify_property_list_changed()

var _override_saved_value: Node2D


func _validate_property(property: Dictionary) -> void:
	if property.name == "target":
		if override != null:
			target = override
			property.usage |= PROPERTY_USAGE_READ_ONLY
		else:
			# Avoid `previously freed` values
			target = _override_saved_value if _override_saved_value != null else null
