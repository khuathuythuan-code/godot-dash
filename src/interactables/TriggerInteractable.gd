class_name TriggerInteractable
extends Interactable

func _ready() -> void:
	super()
	#đoạn code này
	monitoring = false
	await get_tree().process_frame
	await get_tree().process_frame
	monitoring = true
	#chữa lỗi khiến logic của endLevelTrigger vẫn giữ signal body_entered
	#player sẽ tự kích hoạt trạng thái end game
	#đoạn code trên sẽ reset area2d
	body_entered.connect(func(player: Player): 
		interacted.emit(player)
		
		)
	
