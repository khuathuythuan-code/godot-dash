extends Control
class_name StatController

@onready var time_label: Label = $TimeLabel
@onready var attemp_label: Label = $Control/AttempLabel
@onready var jump_label: Label = $Control2/JumpLabel


var time_elapsed: float = 0.0
var jump_count: int = 0

func _process(delta: float) -> void:
	if LevelManager.level_playing and !get_tree().paused:
		# Cộng dồn thời gian trôi qua (tính bằng giây)
		time_elapsed += delta
		
		# Tính toán Phút, Giây và Tích tắc
		var minutes: int = int(time_elapsed) / 60
		var seconds: int = int(time_elapsed) % 60
		# Lấy phần thập phân rồi nhân với 100 để ra 2 chữ số "tích tắc" (centi-seconds)
		var tictac: int = int((time_elapsed - int(time_elapsed)) * 100)
		
		# Định dạng chuỗi hiển thị luôn có 2 chữ số (00:00:00)
		time_label.text = "%02d:%02d:%02d" % [minutes, seconds, tictac]
		
		var pause_menu = LevelManager.game_scene.pause_menu as CyberPunkPauseMenu
		attemp_label.text = str(pause_menu.attempt_count)
		jump_label.text = str(jump_count)
	
		if Input.is_action_just_pressed("jump"):
			jump_count+=1
			

func refresh():
	time_elapsed = 0.0
	jump_count = 0
