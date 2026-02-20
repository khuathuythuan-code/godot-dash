extends VBoxContainer
class_name IconGarage

@export var preview_icons: HBoxContainer

func _on_ship_pressed() -> void:
	var ship_sprite := preview_icons.get_node(^"Ship/Ship")	
	var jetpack_sprite := preview_icons.get_node(^"Ship/Jetpack")
	if ship_sprite.visible:
		ship_sprite.hide()
		jetpack_sprite.show()
	else:
		ship_sprite.show()
		jetpack_sprite.hide()
	
