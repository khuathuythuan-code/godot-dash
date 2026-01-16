extends PopupMenu

@export var game_scene: Node2D
@export var side_panel: Container
@export var bottom_panel: Container

# MOBILE ONLY

func _ready() -> void:
	if not Config.is_touch_screen:
		queue_free()

func _on_index_pressed(index:int) -> void:
	match index:
		0: # Menu
			game_scene.get_node("PauseMenuLayer/PauseMenu")._on_continue_pressed()
	set_item_checked(index, not is_item_checked(index))
