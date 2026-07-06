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
	# Đọc thư mục levels ngay khi game chạy
	var dir := DirAccess.open(Constants.LEVEL_DIR)
	
	levels = dir.get_files()
	pre_btn.pressed.connect(_on_pre_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	

	_update_level_display()



# Đổi tên từ loadLevels thành _update_level_display cho đúng bản chất (chỉ cập nhật chữ hiển thị)
func _update_level_display() -> void:
	if levels.size() == 0: return
	for file_name in levels:
		var level_name: String = file_name.replace(".json", "")
		var level_item = level_item_scene.instantiate() as LevelItem
		item_container.add_child(level_item)
		level_item.set_level_name(level_name)
	


# Hàm xử lý khi bấm nút Play
func _on_play_pressed() -> void:
	if levels.size() == 0: return
	_play_level("%s.json" % selected_carousel_node.title_label.text.strip_edges())


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
	
		
	get_tree().change_scene_to_packed(AssetManager.game_scene_packed)
	


func _process(delta: float) -> void:
	selected_carousel_node = $CarouselContainer. position_offset_node.get_child($CarouselContainer. selected_index) 
	#print(selected_carousel_node.name) 
	#print(selected_carousel_node.size) 
	#print (selected_carousel_node.position)


func _on_pre_pressed() -> void:
	carousel_container._left()

func _on_next_pressed() -> void:
	carousel_container._right()
