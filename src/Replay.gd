extends Resource
class_name Replay

@export var replay: Array[PackedInt32Array] = [] # [jump_pressed as int, direction]

func reset() -> void:
	replay.clear()


func save(name: String) -> void:
	DirAccess.remove_absolute(Constants.REPLAYS_DIR + name + ".res")
	ResourceSaver.save(self, Constants.REPLAYS_DIR + name + ".res", ResourceSaver.SaverFlags.FLAG_COMPRESS)
