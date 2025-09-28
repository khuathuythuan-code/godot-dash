extends PopupMenu

@export var game_scene: Node2D
@export var side_panel: Container
@export var bottom_panel: Container


func _on_index_pressed(index:int) -> void:
	match index:
		0: # Grid
			game_scene.get_node("EditorGridParallax/EditorGrid").visible = not is_item_checked(index)
		1: # Side Panel
			side_panel.visible = not is_item_checked(index)
		2: # Bottom Panel
			bottom_panel.visible = not is_item_checked(index)
		3: # Toggle maximize viewport
			toggle_maximize_viewport()
	set_item_checked(index, not is_item_checked(index))


func toggle_maximize_viewport() -> void:
	var panels := [side_panel, bottom_panel]
	for i in panels.size():
		var panel: Control = panels[i]
		if is_item_checked(get_item_index(i + 1)):
			panel.visible = not panel.visible
