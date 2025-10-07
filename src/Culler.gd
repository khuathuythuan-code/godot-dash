class_name LevelCuller
extends Node

@onready var amount: int = Config.config.cull_limit
@onready var parent: Node2D = get_parent()

func _ready() -> void:
	$Timer.wait_time = Config.config.cull_interval

func cull(objects: Array[Node]) -> void:
	var object_dictionary: Dictionary[Vector2, Array]
	for object in objects:
		if object is not Node2D:
			continue
		var position_array: Array = object_dictionary.get_or_add(object.position, [])
		position_array.append(object)
		object_dictionary[object.position] = position_array
	for position in object_dictionary:
		var index: int = 0
		for object in object_dictionary[position]:
			index += 1
			if index < amount:
				if Config.config.cull_sprites:
					object.call_deferred("show")
				if Config.config.cull_hitboxes:
					object.find_child("Hitbox").set_deferred("disabled", false)
				continue
			if Config.config.cull_sprites:
				object.call_deferred("hide")
			if Config.config.cull_hitboxes:
				object.find_child("Hitbox").set_deferred("disabled", true)
