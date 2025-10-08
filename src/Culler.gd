class_name LevelCuller
extends Node

@onready var parent: Node2D = get_parent()
@onready var cull_sprites: bool = Config.config.cull_sprites
@onready var cull_hitboxes: bool = Config.config.cull_hitboxes
@onready var sprites_cull_limit: int = Config.config.sprites_cull_limit
@onready var hitboxes_cull_limit: int = Config.config.hitboxes_cull_limit

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
			if cull_hitboxes:
				if index < hitboxes_cull_limit:
					object.find_child("Hitbox").set_deferred("disabled", false)
				else:
					object.call_deferred("hide")
			if cull_sprites:
				if index < sprites_cull_limit:
					object.call_deferred("show")
				else:
					object.find_child("Hitbox").set_deferred("disabled", true)
