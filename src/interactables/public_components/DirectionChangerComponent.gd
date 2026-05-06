class_name DirectionChangerComponent
extends Component

signal direction_changed(new_direction: Direction)

enum Direction {
	KEEP,
	FLIP,
	FORWARDS,
	BACKWARDS,
}

@export var direction := Direction.KEEP:
	set(value):
		direction = value
		direction_changed.emit(value)


func _ready() -> void:
	parent.interacted.connect(set_direction)


func set_direction(player: Player):
	match direction:
		Direction.FLIP:
			player.horizontal_direction *= -1
		Direction.FORWARDS:
			player.horizontal_direction = 1
		Direction.BACKWARDS:
			player.horizontal_direction = -1
