extends Component
class_name TargetColorChannelComponent

signal type_changed(type: Type)
signal changed(target_color_channel: String)

enum Type {
	CUSTOM,
	LEVEL,
}

@export var channel_type: Type:
	set(value):
		channel_type = value
		type_changed.emit(value)
		match value:
			Type.CUSTOM:
				changed.emit(target_color_channel)
			Type.LEVEL:
				changed.emit(Constants.SpecialColorChannel.find_key(target_level_channel).capitalize())
		notify_property_list_changed()
@export_placeholder("Color channel name") var target_color_channel: String:
	set(value):
		target_color_channel = value
		if channel_type == Type.CUSTOM:
			changed.emit(value)
@export var	target_level_channel: Constants.SpecialColorChannel:
	set(value):
		target_level_channel = value
		if channel_type == Type.LEVEL:
			changed.emit(Constants.SpecialColorChannel.find_key(value).capitalize())


func _validate_property(property: Dictionary) -> void:
	if property.name == "target_color_channel" and channel_type != Type.CUSTOM:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "target_level_channel" and channel_type != Type.LEVEL:
		property.usage = PROPERTY_USAGE_NO_EDITOR
