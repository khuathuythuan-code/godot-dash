extends VBoxContainer

class_name IconGarage

@export var preview_icons: HBoxContainer
@export var icon_selector: GridContainer
@export var icons: Dictionary[PreviewIcon.Icon, Array] = {
	PreviewIcon.Icon.CUBE: [],
	PreviewIcon.Icon.SHIP: [],
	PreviewIcon.Icon.JETPACK: [],
	PreviewIcon.Icon.UFO: [],
	PreviewIcon.Icon.BALL: [],
	PreviewIcon.Icon.WAVE: [],
	PreviewIcon.Icon.ROBOT: [],
	PreviewIcon.Icon.SPIDER: [],
	PreviewIcon.Icon.SWING: [],
	PreviewIcon.Icon.TRAIL: [],
	PreviewIcon.Icon.DEATH_EFFECT: [],
}

var tab: PreviewIcon.Icon = PreviewIcon.Icon.CUBE


func _ready() -> void:
	var icon_path := DirAccess.open(Constants.ICON_DIR)
	for type_dir in icon_path.get_directories():
		var icon_type: PreviewIcon.Icon
		match type_dir:
			"cube":
				icon_type = PreviewIcon.Icon.CUBE
			"ship":
				icon_type = PreviewIcon.Icon.SHIP
			"jetpack":
				icon_type = PreviewIcon.Icon.JETPACK
			"ufo":
				icon_type = PreviewIcon.Icon.UFO
			"ball":
				icon_type = PreviewIcon.Icon.BALL
			"wave":
				icon_type = PreviewIcon.Icon.WAVE
			# "robot": Non existant
			# 	icon_type = PreviewIcon.Icon.ROBOT
			"spider":
				icon_type = PreviewIcon.Icon.SPIDER
			"swing":
				icon_type = PreviewIcon.Icon.SWING
			# "trail": Not on this branch
			# icon_type = PreviewIcon.Icon.TRAIL
			"death_effect":
				icon_type = PreviewIcon.Icon.DEATH_EFFECT
			_:
				continue

		var textures_dir: PackedStringArray
		match icon_type:
			PreviewIcon.Icon.WAVE, PreviewIcon.Icon.SPIDER, PreviewIcon.Icon.SWING, PreviewIcon.Icon.DEATH_EFFECT:
				textures_dir = DirAccess.open(Constants.ICON_DIR.path_join(type_dir)).get_directories()
			_:
				textures_dir = DirAccess.open(Constants.ICON_DIR.path_join(type_dir)).get_files()
		for icon: String in textures_dir:
			if icon.contains(".import"):
				continue
			icons[icon_type].append(Constants.ICON_DIR.path_join(type_dir).path_join(icon))
	refresh()


func refresh() -> void:
	var loaded_preview_icon = load("res://scenes/components/game_components/PreviewIcon.tscn")
	for child in icon_selector.get_children():
		child.queue_free()

	for icon_type in icons:
		if icon_type != tab:
			continue
		for icon in icons[icon_type]:
			var button := BouncyButton.new()
			var preview_icon: PreviewIcon = loaded_preview_icon.instantiate()
			preview_icon.gamemode = icon_type
			preview_icon.icon_path = icon
			preview_icon.icon_scale = 0.5
			preview_icon.custom_minimum_size = Vector2(96, 96)
			preview_icon.get_node(^"Sprite").expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
			button.z_index = 4096
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size = Vector2(96, 96)
			icon_selector.add_child(button)
			button.add_child(preview_icon)
			button.pressed.connect(_on_icon_pressed.bind(preview_icon))
	update_icons()


func update_icons() -> void:
	preview_icons.get_node(^"Cube").icon_path = Config.icons[PreviewIcon.Icon.CUBE]["path"]
	preview_icons.get_node(^"Ship/Ship").icon_path = Config.icons[PreviewIcon.Icon.SHIP]["path"]
	preview_icons.get_node(^"Ship/Jetpack").icon_path = Config.icons[PreviewIcon.Icon.JETPACK]["path"]
	preview_icons.get_node(^"UFO").icon_path = Config.icons[PreviewIcon.Icon.UFO]["path"]
	preview_icons.get_node(^"Ball").icon_path = Config.icons[PreviewIcon.Icon.BALL]["path"]
	preview_icons.get_node(^"Wave").icon_path = Config.icons[PreviewIcon.Icon.WAVE]["path"]
	# preview_icons.get_node(^"Robot").icon_path = Config.icons[PreviewIcon.Icon.ROBOT]["path"]
	preview_icons.get_node(^"Spider").icon_path = Config.icons[PreviewIcon.Icon.SPIDER]["path"]
	preview_icons.get_node(^"Swing").icon_path = Config.icons[PreviewIcon.Icon.SWING]["path"]
	# preview_icons.get_node(^"Trail").icon_path = Config.icons[PreviewIcon.Icon.TRAIL]["path"]
	# preview_icons.get_node(^"DeathEffect").icon_path = Config.icons[PreviewIcon.Icon.DEATH_EFFECT]["path"]


func _on_icon_pressed(icon: PreviewIcon) -> void:
	match icon.gamemode:
		PreviewIcon.Icon.CUBE:
			Config.icons[PreviewIcon.Icon.CUBE]["path"] = icon.icon_path
		PreviewIcon.Icon.SHIP:
			Config.icons[PreviewIcon.Icon.SHIP]["path"] = icon.icon_path
			preview_icons.get_node(^"Ship/Ship").show()
			preview_icons.get_node(^"Ship/Jetpack").hide()
		PreviewIcon.Icon.JETPACK:
			Config.icons[PreviewIcon.Icon.JETPACK]["path"] = icon.icon_path
			preview_icons.get_node(^"Ship/Ship").hide()
			preview_icons.get_node(^"Ship/Jetpack").show()
		PreviewIcon.Icon.UFO:
			Config.icons[PreviewIcon.Icon.UFO]["path"] = icon.icon_path
		PreviewIcon.Icon.BALL:
			Config.icons[PreviewIcon.Icon.BALL]["path"] = icon.icon_path
		PreviewIcon.Icon.WAVE:
			Config.icons[PreviewIcon.Icon.WAVE]["path"] = icon.icon_path
		PreviewIcon.Icon.ROBOT:
			Config.icons[PreviewIcon.Icon.ROBOT]["path"] = icon.icon_path
		PreviewIcon.Icon.SPIDER:
			Config.icons[PreviewIcon.Icon.SPIDER]["path"] = icon.icon_path
		PreviewIcon.Icon.SWING:
			Config.icons[PreviewIcon.Icon.SWING]["path"] = icon.icon_path
		PreviewIcon.Icon.TRAIL:
			Config.icons[PreviewIcon.Icon.TRAIL]["path"] = icon.icon_path
		PreviewIcon.Icon.DEATH_EFFECT:
			Config.icons[PreviewIcon.Icon.DEATH_EFFECT]["path"] = icon.icon_path
	Config.save()
	update_icons()


func _on_tab_changed(value: int) -> void:
	match value:
		0:
			tab = PreviewIcon.Icon.CUBE
		1:
			tab = PreviewIcon.Icon.SHIP
		2:
			tab = PreviewIcon.Icon.JETPACK
		3:
			tab = PreviewIcon.Icon.UFO
		4:
			tab = PreviewIcon.Icon.BALL
		5:
			tab = PreviewIcon.Icon.WAVE
		6:
			tab = PreviewIcon.Icon.ROBOT
		7:
			tab = PreviewIcon.Icon.SPIDER
		8:
			tab = PreviewIcon.Icon.SWING
		9:
			tab = PreviewIcon.Icon.TRAIL
		10:
			tab = PreviewIcon.Icon.DEATH_EFFECT
	refresh()


func _on_ship_pressed() -> void:
	var ship_sprite := preview_icons.get_node(^"Ship/Ship")
	var jetpack_sprite := preview_icons.get_node(^"Ship/Jetpack")
	if ship_sprite.visible:
		ship_sprite.hide()
		jetpack_sprite.show()
	else:
		ship_sprite.show()
		jetpack_sprite.hide()
