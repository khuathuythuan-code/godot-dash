extends CanvasLayer

var menu_tween: Tween
var enable_escape := 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and enable_escape == 1 and not get_viewport().gui_get_focus_owner() is LineEdit:
		_hide_menu()
	
	if enable_escape == 2:
		enable_escape = 1


func _hide_menu() -> void:
	if $SettingsContainer.position.y == 0:
		menu_tween = create_tween()
		menu_tween.tween_property($SettingsContainer, "position:y", -$SettingsContainer.get_viewport_rect().size.y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


func _on_settings_pressed() -> void:
	if $SettingsContainer.position.y == -$SettingsContainer.get_viewport_rect().size.y:
		menu_tween = create_tween()
		menu_tween.tween_property($SettingsContainer, "position:y", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


func _enable_escape() -> void:
	enable_escape = 2


func _disable_escape() -> void:
	enable_escape = 0
