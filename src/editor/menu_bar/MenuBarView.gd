extends PopupMenu
class_name MenuBarView

enum {
	GRID,
	SIDE_PANEL,
	BOTTOM_PANEL,
	TOGGLE_MAXIMIZE_VIEWPORT,
}

@export var game_scene: Node2D
@export var side_panel: Container
@export var bottom_panel: Container


func _on_index_pressed(index:int) -> void:
	match index:
		GRID:
			game_scene.get_node("EditorGridParallax/EditorGrid").visible = not is_item_checked(index)
		SIDE_PANEL:
			side_panel.visible = not is_item_checked(index)
		BOTTOM_PANEL:
			bottom_panel.visible = not is_item_checked(index)
		TOGGLE_MAXIMIZE_VIEWPORT:
			toggle_maximize_viewport()
	set_item_checked(index, not is_item_checked(index))


func toggle_maximize_viewport() -> void:
	var panels := [side_panel, bottom_panel]
	for i in panels.size():
		var panel: Control = panels[i]
		if is_item_checked(get_item_index(i + 1)):
			panel.visible = not panel.visible
