extends Node


func _ready() -> void:
	if Config.config.input_map.is_empty():
		for action in InputMap.get_actions():
			Config.config.input_map.set(action, InputMap.action_get_events(action))
			Config.config.save()
	else:
		for action in Config.config.input_map:
			InputMap.action_erase_events(action)
			var events = Config.config.input_map[action]
			for event in events:
				InputMap.action_add_event(action, event)

