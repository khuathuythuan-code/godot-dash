class_name TriggerInteractable
extends Interactable

func _ready() -> void:
	super()
	#đoạn code này
	monitoring = false
	await get_tree().process_frame
	await get_tree().process_frame
	monitoring = true
	#chữa lỗi hút vào trigger
	body_entered.connect(func(player: Player): 
		interacted.emit(player)
		
		)
	
