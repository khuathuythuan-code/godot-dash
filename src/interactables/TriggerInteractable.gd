class_name TriggerInteractable
extends Interactable

func _ready() -> void:
	super()
	body_entered.connect(func(player: Player): interacted.emit(player))
