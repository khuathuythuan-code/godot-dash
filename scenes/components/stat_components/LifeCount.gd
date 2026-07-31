extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var life_count_label: Label = $Control/MarginContainer/HBoxContainer/LifeCountLabel

var _lives: int = 100

var lives: int:
	get:
		return _lives
	set(value):
		if value == 0:
			value = 100
		_lives = max(value, 0)

func _ready():
	lives = 100

func _process(delta: float) -> void:
	life_count_label.text = str(_lives)
