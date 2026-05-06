class_name Replay
extends Resource

@export var data: Array[PackedByteArray] = [] # [jump_pressed as int, direction]
@export var level_name: String = "Level"


func reset() -> void:
	data.clear()


func save(name: String) -> void:
	DirAccess.remove_absolute(Constants.REPLAYS_DIR + name + ".res")
	ResourceSaver.save(self, Constants.REPLAYS_DIR + name + ".res", ResourceSaver.SaverFlags.FLAG_COMPRESS)
