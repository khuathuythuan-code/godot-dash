extends Control
class_name ColorChannelEditor

@export var button_group: ButtonGroup
@export var separator: HSeparator
@export var properties_container: VBoxContainer

@onready var color_channel_item := preload("res://scenes/components/game_components/ColorChannelItem.tscn")


func _ready() -> void:
	populate_item_list.call_deferred()


func populate_item_list() -> void:
	for channel in LevelManager.current_level.color_channels:
		_add_channel(channel.associated_group.trim_prefix(ColorChannelItem.COLOR_CHANNEL_GROUP_PREFIX), channel)


func clear_item_list() -> void:
	%ColorChannelContainer.get_children().map(func(child: Node): child.queue_free())
	hide_properties()
	%"Copy channel".reset()
	%Channel.reset()
	%Color.reset()
	%Hue.reset()
	%Saturation.reset()
	%Value.reset()
	%Intensity.reset()
	%Alpha.reset()
	%Channel.hide()
	%Color.show()


func _on_button_pressed() -> void:
	_add_channel(%LineEdit.get_text())
	%LineEdit.clear()
	# TODO "keep focus" doesn't work
	if not Input.is_action_pressed(&"ui_accept_keep_focus"):
		get_viewport().gui_release_focus()


func _on_line_edit_text_submitted(new_text:String) -> void:
	_add_channel(new_text)
	%LineEdit.clear()
	get_viewport().gui_release_focus()


func _add_channel(channel_name: String, data: ColorChannelData = null) -> void:
	if channel_name.is_empty() or (channel_name in %ColorChannelContainer.get_children()
			.map(func(color_channel: ColorChannelItem): return color_channel.channel_name)):
		return
	var channel_item := color_channel_item.instantiate() as ColorChannelItem
	channel_item.channel_name = channel_name
	channel_item.data = data
	channel_item.selected.connect(show_properties)
	channel_item.unselected.connect(hide_properties)
	channel_item.update()
	channel_item.register()
	%ColorChannelContainer.add_child(channel_item)


func hide_properties() -> void:
	separator.hide()
	properties_container.hide()


func show_properties() -> void:
	separator.show()
	properties_container.show()
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	%"Copy channel".set_value(channel_item.data.copy)
	%Channel.set_value(channel_item.data.copied_channel)
	%Color.set_value(channel_item.data.color)
	%Hue.set_value(channel_item.data.hsv_shift[0])
	%Saturation.set_value(channel_item.data.hsv_shift[1])
	%Value.set_value(channel_item.data.hsv_shift[2])
	%Intensity.set_value(channel_item.data.intensity)
	%Alpha.set_value(channel_item.data.intensity)
	%Channel.visible = channel_item.data.copy
	%Color.visible = not channel_item.data.copy


func _on_color_value_changed(value: Color) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.set_color(value)


func _on_copy_channel_value_changed(value: bool) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	var change_property_visibility := func(_value: bool):
		%Color.visible = not _value
		%Channel.visible = _value
	var version_history: UndoRedo = Editor.root.level.version_history
	version_history.create_action("%s copy color of color channel %s" % ["Enabled" if value else "Disabled", channel_item.channel_name])
	version_history.add_do_method(channel_item.data.set_copy.bind(value))
	version_history.add_do_method(change_property_visibility.bind(value))
	version_history.add_do_method(%"Copy channel".set_value_no_signal.bind(value))
	version_history.add_undo_method(channel_item.data.set_copy.bind(channel_item.data.copy))
	version_history.add_undo_method(change_property_visibility.bind(channel_item.data.copy))
	version_history.add_undo_method(%"Copy channel".set_value_no_signal.bind(channel_item.data.copy))
	version_history.commit_action()


func _on_channel_value_changed(value: ColorChannelData.CopyColor) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	var version_history: UndoRedo = Editor.root.level.version_history
	version_history.create_action("Set copied channel of color channel %s" % channel_item.channel_name)
	version_history.add_do_method(channel_item.data.set_copied_channel.bind(value))
	version_history.add_undo_method(channel_item.data.set_copied_channel.bind(channel_item.data.copied_channel))
	version_history.commit_action()


func _on_hue_value_changed(value: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	var new_hsv_shift := channel_item.data.hsv_shift.duplicate()
	new_hsv_shift[0] = value
	channel_item.data.set_hsv_shift(new_hsv_shift)


func _on_saturation_value_changed(value: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	var new_hsv_shift := channel_item.data.hsv_shift.duplicate()
	new_hsv_shift[1] = value
	channel_item.data.set_hsv_shift(new_hsv_shift)


func _on_value_value_changed(value: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	var new_hsv_shift := channel_item.data.hsv_shift.duplicate()
	new_hsv_shift[2] = value
	channel_item.data.set_hsv_shift(new_hsv_shift)


func _on_intensity_value_changed(value: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.set_intensity(value)


func _on_alpha_value_changed(value: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.set_alpha(value)


func _on_hsv_shift_folding_changed(is_folded: bool) -> void:
	custom_minimum_size.y = 250 if is_folded else 500


func _on_color_interaction_ended(color: Color, previous: Color) -> void:
	if color == previous:
		return
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	var version_history: UndoRedo = Editor.root.level.version_history
	version_history.create_action("Set color of color channel %s" % channel_item.channel_name)
	version_history.add_do_method(channel_item.data.set_color.bind(color))
	version_history.add_do_method(%Color.set_value_no_signal.bind(color))
	version_history.add_undo_method(channel_item.data.set_color.bind(previous))
	version_history.add_undo_method(%Color.set_value_no_signal.bind(previous))
	version_history.commit_action()


func _on_hue_interaction_ended(value: float, previous: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.hsv_shift[0] = previous
	channel_item.data.set_hsv_shift(channel_item.data.hsv_shift)
	var new_hsv_shift := channel_item.data.hsv_shift.duplicate()
	new_hsv_shift[0] = value
	var version_history: UndoRedo = Editor.root.level.version_history
	version_history.create_action("Set modulation hue of color channel %s" % channel_item.channel_name)
	version_history.add_do_method(channel_item.data.set_hsv_shift.bind(new_hsv_shift))
	version_history.add_do_method(%Hue.set_value_no_signal.bind(value))
	version_history.add_undo_method(channel_item.data.set_hsv_shift.bind(channel_item.data.hsv_shift))
	version_history.add_undo_method(%Hue.set_value_no_signal.bind(channel_item.data.hsv_shift[0]))
	version_history.commit_action()


func _on_saturation_interaction_ended(value: float, previous: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.hsv_shift[1] = previous
	channel_item.data.set_hsv_shift(channel_item.data.hsv_shift)
	var new_hsv_shift := channel_item.data.hsv_shift.duplicate()
	new_hsv_shift[1] = value
	var version_history: UndoRedo = Editor.root.level.version_history
	version_history.create_action("Set modulation saturation of color channel %s" % channel_item.channel_name)
	version_history.add_do_method(channel_item.data.set_hsv_shift.bind(new_hsv_shift))
	version_history.add_do_method(%Saturation.set_value_no_signal.bind(value))
	version_history.add_undo_method(channel_item.data.set_hsv_shift.bind(channel_item.data.hsv_shift))
	version_history.add_undo_method(%Saturation.set_value_no_signal.bind(channel_item.data.hsv_shift[1]))
	version_history.commit_action()


func _on_value_interaction_ended(value: float, previous: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	channel_item.data.hsv_shift[2] = previous
	channel_item.data.set_hsv_shift(channel_item.data.hsv_shift)
	var new_hsv_shift := channel_item.data.hsv_shift.duplicate()
	new_hsv_shift[2] = value
	var version_history: UndoRedo = Editor.root.level.version_history
	version_history.create_action("Set modulation value of color channel %s" % channel_item.channel_name)
	version_history.add_do_method(channel_item.data.set_hsv_shift.bind(new_hsv_shift))
	version_history.add_do_method(%Value.set_value_no_signal.bind(value))
	version_history.add_undo_method(channel_item.data.set_hsv_shift.bind(channel_item.data.hsv_shift))
	version_history.add_undo_method(%Value.set_value_no_signal.bind(channel_item.data.hsv_shift[2]))
	version_history.commit_action()


func _on_intensity_interaction_ended(value: float, previous: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	var version_history: UndoRedo = Editor.root.level.version_history
	version_history.create_action("Set modulation intensity of color channel %s" % channel_item.channel_name)
	version_history.add_do_method(channel_item.data.set_intensity.bind(value))
	version_history.add_do_method(%Intensity.set_value_no_signal.bind(value))
	version_history.add_undo_method(channel_item.data.set_intensity.bind(previous))
	version_history.add_undo_method(%Intensity.set_value_no_signal.bind(previous))
	version_history.commit_action()


func _on_alpha_interaction_ended(value: float, previous: float) -> void:
	if button_group.get_pressed_button() == null:
		return
	var channel_item := button_group.get_pressed_button().get_parent() as ColorChannelItem
	var version_history: UndoRedo = Editor.root.level.version_history
	version_history.create_action("Set modulation alpha of color channel %s" % channel_item.channel_name)
	version_history.add_do_method(channel_item.data.set_alpha.bind(value))
	version_history.add_do_method(%Alpha.set_value_no_signal.bind(value))
	version_history.add_undo_method(channel_item.data.set_alpha.bind(previous))
	version_history.add_undo_method(%Alpha.set_value_no_signal.bind(previous))
	version_history.commit_action()

