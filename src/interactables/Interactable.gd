extends Area2D
class_name Interactable

@warning_ignore("unused_signal")
signal interacted(player: Player)

var components: Array[Component]


func _ready() -> void:
	if has_node("Hitbox"):
		$Hitbox.debug_color = Color("00ff0033")


func register_public(component: Component) -> void:
	components.append(component)


func has(component_type: Script) -> bool:
	return components.any(func(component): return component and component.get_script() == component_type)


func query(component_type: Script) -> Component:
	var component_idx := components.find_custom(func(component): return component and component.get_script() == component_type)
	return components[component_idx] if component_idx >= 0 else null
