class_name IconGarage
extends VBoxContainer

@export var preview_icons: HBoxContainer
@export var icon_selector: GridContainer
#@export var icons: Dictionary[PreviewIcon.Icon, Array] = {
@export var icons: Dictionary = {
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
	reload()


func reload() -> void:
	if not DirAccess.dir_exists_absolute(Constants.CUSTOM_ICON_DIR):
		DirAccess.make_dir_recursive_absolute(Constants.CUSTOM_ICON_DIR)
	for directory: String in ["cube", "ship", "jetpack", "ufo", "ball", "wave", "spider", "trail", "death_effect"]:
		directory = Constants.CUSTOM_ICON_DIR + directory
		if not DirAccess.dir_exists_absolute(directory):
			DirAccess.make_dir_recursive_absolute(directory)
	for icon_type: PreviewIcon.Icon in icons:
		icons[icon_type].clear()
	#for icon_path in [Constants.ICON_DIR, Constants.CUSTOM_ICON_DIR]:
		#var opened_icon_path: DirAccess = DirAccess.open(icon_path)
		#for type_dir in opened_icon_path.get_directories():

	# 1. Load built-in icons directly (bypassing res:// DirAccess scanning which fails on Web exports)
	var builtin_icons: Dictionary[PreviewIcon.Icon, Array] = {
		PreviewIcon.Icon.CUBE: [
			"res://assets/textures/player/cube/Cube2.png"
		],
		PreviewIcon.Icon.SHIP: [
			"res://assets/textures/player/ship/Ship4.png"
		],
		PreviewIcon.Icon.JETPACK: ["res://assets/textures/player/jetpack/Jetpack1.svg"],
		PreviewIcon.Icon.UFO: ["res://assets/textures/player/ufo/Ufo1.svg"],
		PreviewIcon.Icon.BALL: [
			"res://assets/textures/player/ball/Ball3.png"
		],
		PreviewIcon.Icon.WAVE: [
			"res://assets/textures/player/wave/Wave2.png"
		],
		PreviewIcon.Icon.ROBOT: [],
		PreviewIcon.Icon.SPIDER: [
			"res://assets/textures/player/spider/Spider1"
			],
		PreviewIcon.Icon.SWING: ["res://assets/textures/player/swing/Swing1"],
		PreviewIcon.Icon.TRAIL: [
            "res://assets/textures/player/trail/Trail2.png"
		],
		PreviewIcon.Icon.DEATH_EFFECT: ["res://assets/textures/player/death_effect/DeathEffect1"],
	}


	for icon_type: PreviewIcon.Icon in icons:
		if builtin_icons.has(icon_type):
			icons[icon_type].append_array(builtin_icons[icon_type])

	# 2. Scan custom user icons directory (DirAccess works perfectly on user:// even in Web exports)
	var opened_custom_path := DirAccess.open(Constants.CUSTOM_ICON_DIR)
	if opened_custom_path:
		for type_dir in opened_custom_path.get_directories():
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
				"trail":
					icon_type = PreviewIcon.Icon.TRAIL
				"death_effect":
					icon_type = PreviewIcon.Icon.DEATH_EFFECT
				_:
					continue

			var textures_dir: PackedStringArray
			match icon_type:
				PreviewIcon.Icon.SPIDER, PreviewIcon.Icon.SWING, PreviewIcon.Icon.DEATH_EFFECT:
					#textures_dir = DirAccess.open(icon_path.path_join(type_dir)).get_directories()
					var sub_dir := Constants.CUSTOM_ICON_DIR.path_join(type_dir)
					var sub_access := DirAccess.open(sub_dir)
					if sub_access:
						textures_dir = sub_access.get_directories()
				_:
					#textures_dir = DirAccess.open(icon_path.path_join(type_dir)).get_files()
					var sub_dir := Constants.CUSTOM_ICON_DIR.path_join(type_dir)
					var sub_access := DirAccess.open(sub_dir)
					if sub_access:
						textures_dir = sub_access.get_files()
						
			for icon: String in textures_dir:
				#if icon.contains(".import"):
					#continue
				#icons[icon_type].append(icon_path.path_join(type_dir).path_join(icon))
				var clean_icon := icon.trim_suffix(".import").trim_suffix(".remap")
				var full_path := Constants.CUSTOM_ICON_DIR.path_join(type_dir).path_join(clean_icon)
				if not icons[icon_type].has(full_path):
					icons[icon_type].append(full_path)
	refresh()


func refresh() -> void:
	var loaded_preview_icon: PackedScene = load("res://scenes/components/game_components/PreviewIcon.tscn")
	for child in icon_selector.get_children():
		child.queue_free()
	var icon_type: PreviewIcon.Icon = tab
	for icon: String in icons[icon_type]:
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
		button.add_child(preview_icon)
		icon_selector.add_child(button)
		button.pressed.connect(_on_icon_pressed.bind(preview_icon))
	update_icons()


func update_icons() -> void:
	preview_icons.get_node(^"Cube").icon_path = Config.icons[PreviewIcon.Icon.CUBE].path
	preview_icons.get_node(^"Ship/Ship").icon_path = Config.icons[PreviewIcon.Icon.SHIP].path
	preview_icons.get_node(^"Ship/Jetpack").icon_path = Config.icons[PreviewIcon.Icon.JETPACK].path
	preview_icons.get_node(^"UFO").icon_path = Config.icons[PreviewIcon.Icon.UFO].path
	preview_icons.get_node(^"Ball").icon_path = Config.icons[PreviewIcon.Icon.BALL].path
	preview_icons.get_node(^"Wave").icon_path = Config.icons[PreviewIcon.Icon.WAVE].path
	# preview_icons.get_node(^"Robot").icon_path = Config.icons[PreviewIcon.Icon.ROBOT].path
	preview_icons.get_node(^"Spider").icon_path = Config.icons[PreviewIcon.Icon.SPIDER].path
	preview_icons.get_node(^"Swing").icon_path = Config.icons[PreviewIcon.Icon.SWING].path
	#preview_icons.get_node(^"DeathEffect").icon_path = Config.icons[PreviewIcon.Icon.DEATH_EFFECT].path


func _on_icon_pressed(icon: PreviewIcon) -> void:
	Config.icons[icon.gamemode].path = icon.icon_path
	match icon.gamemode:
		PreviewIcon.Icon.SHIP:
			preview_icons.get_node(^"Ship/Ship").show()
			preview_icons.get_node(^"Ship/Jetpack").hide()
		PreviewIcon.Icon.JETPACK:
			preview_icons.get_node(^"Ship/Ship").hide()
			preview_icons.get_node(^"Ship/Jetpack").show()
	Config.save()
	AssetManager.load_icons([icon.gamemode])
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
	var ship_sprite: CanvasItem = preview_icons.get_node(^"Ship/Ship")
	var jetpack_sprite: CanvasItem = preview_icons.get_node(^"Ship/Jetpack")
	ship_sprite.visible = not ship_sprite.visible
	jetpack_sprite.visible = not jetpack_sprite.visible
