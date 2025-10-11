extends PopupMenu

@export var game_scene: Node2D
@export var side_panel: Container
@export var bottom_panel: Container

# MOBILE ONLY

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available() and not OS.is_debug_build():
		queue_free()

func _on_index_pressed(index:int) -> void:
	match index:
		0: # Menu
			$"../../../../../../GameScene/PauseMenuLayer".visible = true
	set_item_checked(index, not is_item_checked(index))
