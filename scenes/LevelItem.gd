extends Control
class_name LevelItem

@onready var title_label: Label = $Label


func set_level_name(level_name: String) -> void:
	# Nếu chưa vào Tree thì đợi, hoặc kiểm tra label trước
	if not is_inside_tree():
		await ready
	title_label.text = level_name
