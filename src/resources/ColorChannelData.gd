extends Resource
class_name ColorChannelData

enum CopyColor {
	BACKGROUND,
	GROUND,
	LINE,
	# TODO implement players colors
	P1,
	P2,
	GLOW,
}

@export var copy: bool
@export var color := Color.WHITE
@export var copied_channel: CopyColor
@export var hsv_shift: Array[float] = [0.0, 0.0, 0.0]
@export var strength: float = 1.0
@export var alpha: float = 1.0
@export var associated_group: String

var watcher: ColorChannelWatcher


func set_copy(should_copy: bool = false) -> ColorChannelData:
	copy = should_copy
	changed.emit()
	return self


func set_color(new_color: Color) -> ColorChannelData:
	color = new_color
	changed.emit()
	return self


func set_copied_channel(new_copied_channel: CopyColor) -> ColorChannelData:
	copied_channel = new_copied_channel
	changed.emit()
	return self


func set_hsv_shift(new_hsv_shift: Array[float]) -> ColorChannelData:
	hsv_shift = new_hsv_shift
	changed.emit()
	return self


func set_strength(new_strength: float) -> ColorChannelData:
	strength = new_strength
	changed.emit()
	return self


func set_alpha(new_alpha: float) -> ColorChannelData:
	alpha = new_alpha
	changed.emit()
	return self


static func to_data(channel: ColorChannelData) -> Dictionary:
	var data: Dictionary
	data.copy = channel.copy
	data.color = channel.color.to_rgba32()
	data.copied_channel = channel.copied_channel
	data.hsv_shift = channel.hsv_shift
	data.strength = channel.strength
	data.alpha = channel.alpha
	data.associated_group = channel.associated_group
	return data


static func from_data(data: Dictionary) -> ColorChannelData:
	var channel := ColorChannelData.new()
	channel.copy = data.copy
	channel.color = Color.hex(data.color)
	channel.copied_channel = data.copied_channel
	channel.hsv_shift.assign(data.hsv_shift)
	channel.strength = data.strength
	channel.alpha = data.alpha
	channel.associated_group = data.associated_group
	return channel
