extends Control

@export var subscene_manager: SubsceneManager
@export var fade_screen: FadeScreen
@onready var display_label: Label = $Label
@onready var play_btn: Button = $"../../../Buttons/Play"
@onready var pre_btn: Button = $"../../../Buttons/Pre"
@onready var next_btn: Button = $"../../../Buttons/Next"

# Đưa danh sách levels ra ngoài làm biến toàn cục của script để các hàm đều dùng được
var levels: Array = []

var current_level_index: int = 0:
	set(value):
		if levels.size() == 0:
			return
			
		# Xử lý cuộn vòng (Wrap-around) chuẩn chỉ
		if value < 0:
			current_level_index = levels.size() - 1
		elif value >= levels.size():
			current_level_index = 0
		else:
			current_level_index = value
		
		# Tự động cập nhật lại UI mỗi khi index thay đổi
		_update_level_display()
	get:
		return current_level_index


func _ready() -> void:
	# Đọc thư mục levels ngay khi game chạy
	var dir := DirAccess.open(Constants.LEVEL_DIR)
	
	if not dir or dir.get_files().size() == 0:
		display_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		display_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		display_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		display_label.text = "No levels found."
		# Ẩn hoặc disable các nút nếu không có level nào
		play_btn.disabled = true
		pre_btn.disabled = true
		next_btn.disabled = true
		return
		
	levels = dir.get_files()
	
	# Kết nối sự kiện cho nút Pre và Next (Sửa lại phép gán)
	pre_btn.pressed.connect(func(): current_level_index -= 1)
	next_btn.pressed.connect(func(): current_level_index += 1)
	
	# Kết nối nút Play MỘT LẦN DUY NHẤT ở đây để tránh trùng lặp tín hiệu
	play_btn.pressed.connect(_on_play_pressed)
	
	# Cập nhật hiển thị màn chơi đầu tiên (index = 0)
	_update_level_display()



# Đổi tên từ loadLevels thành _update_level_display cho đúng bản chất (chỉ cập nhật chữ hiển thị)
func _update_level_display() -> void:
	if levels.size() == 0: return
	
	var file_name: String = levels[current_level_index]
	var level_name: String = file_name.replace(".json", "")
	display_label.text = level_name
	


# Hàm xử lý khi bấm nút Play
func _on_play_pressed() -> void:
	if levels.size() == 0: return
	
	var current_file_name = levels[current_level_index]
	_play_level(current_file_name)


func _play_level(level_name: String) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelPlay.ogg")
	fade_screen.fade_in()
	
	subscene_manager.history.change_phantomcamera(subscene_manager.active_pcam, subscene_manager.quit_game_camera)
	subscene_manager.zoom_in_title_screen_layer()
	
	await get_tree().create_timer(0.5).timeout
	
	# SỬA LỖI: Lấy tên level thực tế thay vì lấy tên Node (name)
	LevelManager.current_level_name = level_name.replace(".json", "")
	LevelManager.attempt = 0
	LevelManager.current_level_path = Constants.LEVEL_DIR + level_name
	
	if DiscordRPCManager.available:
		DiscordRPCHandler.set_details("Playing a level")
		DiscordRPCHandler.refresh()
		
	get_tree().change_scene_to_packed(AssetManager.game_scene_packed)
