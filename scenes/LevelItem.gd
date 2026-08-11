extends Control
class_name LevelItem

@onready var title_label: Label = $Label
@onready var level_info: Control = $Control2
@onready var time_label: Label = $Control2/HBoxContainer3/VBoxContainer2/TimeLabel
@onready var jump_label: Label = $Control2/HBoxContainer3/VBoxContainer3/Label2
@onready var attempt_label: Label = $Control2/HBoxContainer3/VBoxContainer5/AttemptLabel
@onready var completion_label: Label = $Control2/HBoxContainer3/VBoxContainer4/CompletionLabel
@onready var triangle: NinePatchRect = $Control/Triangle
@onready var outline: NinePatchRect = $Control/Outline
@onready var thumbnail_rect: TextureRect = $Control/Control2/Polygon2D/Thumbnail

#func set_level_name(level_name: String) -> void:
	## Nếu chưa vào Tree thì đợi, hoặc kiểm tra label trước
	#if not is_inside_tree():
		#await ready
	#title_label.text = level_name
	#set_best_record()


func set_level_name(level_name: String) -> void:
	# Nếu chưa vào Tree thì đợi
	if not is_inside_tree():
		await ready
	title_label.text = level_name
	set_best_record()
	
	# Đọc ảnh thumbnail từ file JSON tương ứng của màn chơi
	var file_path = Constants.LEVEL_DIR + level_name + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var level_data = JSON.parse_string(json_str)
			if level_data is Dictionary and level_data.has("thumbnail"):
				var thumb_path = level_data.get("thumbnail", "")
				set_thumbnail(thumb_path)
	else:
		set_thumbnail("")

func set_best_record():
	var level_name = title_label.text.strip_edges()
	var record = SaveManager.get_best_record(level_name)
	var best_time = record.get("time", 0.0)
	var best_attempt = record.get("attempt", 0)
	var best_jump = record.get("jump", 0)
	var best_completion: float = record.get("completion", 0.0)
	if best_attempt > 0:
		@warning_ignore("integer_division")
		var minutes: int = int(best_time) / 60
		var seconds: int = int(best_time) % 60
		# Lấy phần thập phân rồi nhân với 100 để ra 2 chữ số "tích tắc" (centi-seconds)
		var tictac: int = int((best_time - int(best_time)) * 100)
		
		# Định dạng chuỗi hiển thị luôn có 2 chữ số (00:00:00)
		time_label.text = "%02d:%02d:%02d" % [minutes, seconds, tictac]
		attempt_label.text = str(best_attempt)
		jump_label.text = str(best_jump)
		completion_label.text = "%.2f%%" % best_completion
	else:
		time_label.text = "--:--:--"
		attempt_label.text = "--"
		jump_label.text = "--"
		completion_label.text = "--"
		
	display_completion_outline(best_completion)
func display_completion_outline(completion: float):
	if completion == 100.0:
		triangle.modulate = Color.YELLOW
		outline.modulate = Color.YELLOW
	else:
		triangle.modulate = Color("ffffff")
		outline.modulate = Color("ffffff")
	

func set_thumbnail(texture_path: String) -> void:
	if texture_path == "" or texture_path == "res://" or DirAccess.dir_exists_absolute(texture_path) or not FileAccess.file_exists(texture_path):
		thumbnail_rect.texture = preload("res://assets/textures/thumbnails/level_default.jpg")
		return
	var texture = load(texture_path)
	if texture is Texture2D:
		thumbnail_rect.texture = texture
