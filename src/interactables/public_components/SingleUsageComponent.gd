extends Marker

class_name SingleUsageComponent

func _ready() -> void:
	parent.interacted.connect(disable)


func disable(_body: Node2D) -> void:
	parent.collision_mask = 0
