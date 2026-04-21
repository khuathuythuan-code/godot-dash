class_name TriggerInteractable
extends Interactable

func _ready() -> void:
	super()
	#khi player đi vào endLeveltrigger ván 1 -> hủy ván, nhưng signal body_enter chưa kịp hủy trong engine 
	#-> đã render lại map -> tuy player chưa chạm vào endLeveltrigger ván 2 tạo nhưng vẫn bị hút vào
	# có lẽ logic chưa kịp điều chỉnh do frame hủy và frame tạo mới quá nhanh
#1. Transform node ≠ Physics body
#Khi set player.global_position = (640), node di chuyển ngay lập tức nhưng physics body cần ít nhất 1 physics frame để sync theo. Trong khoảng thời gian đó, collision detection vẫn dùng vị trí cũ.
#2. Area2D mới tạo ra sẽ emit body_entered cho tất cả body đang overlap tại thời điểm physics frame đầu tiên
#Không quan trọng body có "đi vào" hay không — chỉ cần tại physics frame đầu tiên physics body còn ở vị trí cũ overlap với Area2D mới → body_entered emit ngay.
	monitoring = false
	await get_tree().process_frame
	await get_tree().process_frame
	monitoring = true
	#nên disable area2d mới 2 frame để tránh nhận signal từ area2d cũ
	body_entered.connect(func(player: Player): 
		interacted.emit(player)
		
		)
	
