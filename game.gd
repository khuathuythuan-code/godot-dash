extends Control
@onready var item_container: Control = $CarouselContainer/Control

@export var subscene_manager: SubsceneManager
@export var fade_screen: FadeScreen
@export var pre_btn: Button
@export var next_btn: Button
@export var play_btn: Button
@export var carousel_container: CarouselContainer

var level_item_scene: PackedScene = preload("res://scenes/LevelItem.tscn")
var levels: Array = []
var selected_carousel_node: LevelItem


func _ready() -> void:
	var dir := DirAccess.open(Constants.LEVEL_DIR)
	
	var raw_files = dir.get_files()
	var levels_with_index: Array = []
	
	# 1. Đọc từng file JSON để lấy chỉ số difficulty_index
	for file_name in raw_files:
		if file_name.ends_with(".json"):
			var file_path = Constants.LEVEL_DIR + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var json_str = file.get_as_text()
				file.close()
				var level_data = JSON.parse_string(json_str)
				if level_data is Dictionary:
					# Lấy difficulty_index, nếu không có thì gán giá trị là null
					var diff_idx = level_data.get("difficulty_index", null)
					levels_with_index.append({
						"file_name": file_name,
						"difficulty_index": diff_idx
					})
	
	# 2. Sắp xếp mảng tạm với điều kiện fallback
	levels_with_index.sort_custom(func(a, b):
		var a_has_idx: bool = a["difficulty_index"] != null
		var b_has_idx: bool = b["difficulty_index"] != null
		
		if a_has_idx and b_has_idx:
			# Cả hai đều có: So sánh index trước
			if a["difficulty_index"] == b["difficulty_index"]:
				# Nếu trùng index, xếp theo tên file A-Z
				return a["file_name"].to_lower() < b["file_name"].to_lower()
			return a["difficulty_index"] < b["difficulty_index"]
			
		elif a_has_idx and not b_has_idx:
			# Chỉ a có index -> a lên trước (trả về true)
			return true
			
		elif not a_has_idx and b_has_idx:
			# Chỉ b có index -> b lên trước (trả về false)
			return false
			
		else:
			# Cả hai đều không có index -> sắp xếp theo tên file A-Z
			return a["file_name"].to_lower() < b["file_name"].to_lower()
	)
	
	# 3. Nạp lại danh sách đã sắp xếp vào mảng levels
	levels.clear()
	for item in levels_with_index:
		levels.append(item["file_name"])
	
	pre_btn.pressed.connect(_on_pre_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	
	_update_level_display()

func _process(delta: float) -> void:
	if pre_btn:
		pre_btn.visible = Config.current_level_index != 0
	if next_btn and play_btn:
		next_btn.visible = !(Config.current_level_index == Config.last_level_index)
		play_btn.visible = !(Config.current_level_index == Config.last_level_index)

	selected_carousel_node = $CarouselContainer. position_offset_node.get_child($CarouselContainer. selected_index) 
	#print(selected_carousel_node.name) 
	#print(selected_carousel_node.size) 
	#print (selected_carousel_node.position)
		

# Đổi tên từ loadLevels thành _update_level_display cho đúng bản chất (chỉ cập nhật chữ hiển thị)
func _update_level_display() -> void:
	if levels.size() == 0: return
	for file_name in levels:
		var level_name: String = file_name.replace(".json", "")
		var level_item = level_item_scene.instantiate() as LevelItem
		item_container.add_child(level_item)
		level_item.set_level_name(level_name)
	
	# Tính và gán giá trị độ khó cho slider của từng level item
	_update_levels_difficulty()
	
	var coming_soon_level_item = level_item_scene.instantiate() as LevelItem
	item_container.add_child(coming_soon_level_item)
	coming_soon_level_item.set_level_name("Coming Soon")
	coming_soon_level_item.level_info.visible = false
	Config.last_level_index = item_container.get_child_count() - 1


# Hàm tính và gán giá trị difficulty_slider cho từng level item dựa trên độ khó nhân lên
func _update_levels_difficulty() -> void:
	var total_levels = levels.size()
	if total_levels == 0:
		return
	
	var step: float = 100.0 / total_levels
	for i in range(total_levels):
		var level_item = item_container.get_child(i) as LevelItem
		if level_item:
			var difficulty_val = (i + 1) * step
			level_item.set_difficulty_value(difficulty_val)

	


# Hàm xử lý khi bấm nút Play
func _on_play_pressed() -> void:
	if levels.size() == 0: return
	_play_level("%s.json" % selected_carousel_node.title_label.text.strip_edges())


func _play_level(level_name: String) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	SFXManager.play_sfx("res://assets/sounds/sfx/game_sfx/LevelPlay_2.mp3")
	fade_screen.fade_in()
	
	subscene_manager.history.change_phantomcamera(subscene_manager.active_pcam, subscene_manager.quit_game_camera)
	subscene_manager.zoom_in_title_screen_layer()
	
	await get_tree().create_timer(0.5).timeout
	
	# SỬA LỖI: Lấy tên level thực tế thay vì lấy tên Node (name)
	LevelManager.current_level_name = level_name.replace(".json", "")
	LevelManager.attempt = 0
	LevelManager.current_level_path = Constants.LEVEL_DIR + level_name
	
		
	get_tree().change_scene_to_packed(AssetManager.game_scene_packed)
	



func _on_pre_pressed() -> void:
	carousel_container._left()

func _on_next_pressed() -> void:
	carousel_container._right()
