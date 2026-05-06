## GDImporter.gd
## Autoload: chuyển file GD export JSON thành level JSON của game.
##
## Cách dùng:
##   GDImporter.import_and_play("user://my_gd_level.json")
##   GDImporter.import_to_file("user://my_gd_level.json", "res://src/testlevels/converted.json")
##
## Đăng ký autoload trong Project > Project Settings > Autoload:
##   Name: GDImporter
##   Path: res://src/autoloads/GDImporter.gd

extends Node

signal import_finished(output_path: String)
signal import_failed(reason: String)

const CELL_SIZE: int = 128
const OUTPUT_DIR: String = Constants.LEVEL_DIR

# ══════════════════════════════════════════════════════
# THÊM LOẠI MỚI: chỉ cần thêm 1 entry vào dict này
# key   = tên section trong GD export JSON
# ══════════════════════════════════════════════════════
const OBJECT_REGISTRY: Dictionary = {
	"square": {
		"name": "RegularBlock01",
		"scene_file_path": "scenes/components/level_components/solids/NinePatchBlock.tscn",
		"texture_override": {
			"base": "assets/textures/solids/regular_blocks/RegularBlock01.svg",
			"id": 0
		},
		"children_hsv": [
			{"alpha": 1.0, "hsv_shift": [0.0, 0.0, 0.0], "intensity": 1.0},
			{"alpha": 1.0, "hsv_shift": [0.0, 0.0, 0.0], "intensity": 1.0}
		],
		"has_physics": true,
		"has_texture_override": true,
	},
	"spike": {
		"name": "Spike",
		"scene_file_path": "scenes/components/level_components/hazards/Spike.tscn",
		"children_hsv": [],
		"has_physics": false,
		"has_texture_override": false,
	},
	"spikedecor": {
		"name": "GroundSpike",
		"scene_file_path": "scenes/components/level_components/hazards/GroundSpike.tscn",
		"children_hsv": [],
		"has_physics": false,
		"has_texture_override": false,
	},
	"portal": {
		"name": "Portal",
		"scene_file_path": "scenes/components/level_components/portals/gamemode_portals/ShipPortal.tscn",
		"children_hsv": [],
		"has_physics": false,
		"has_texture_override": false,
	},
	# ── Thêm loại mới tại đây ──────────────────────────
	# "orb": {
	#     "name": "Orb",
	#     "scene_file_path": "scenes/components/level_components/orbs/Orb.tscn",
	#     "children_hsv": [],
	#     "has_physics": false,
	#     "has_texture_override": false,
	# },
	# "pad": {
	#     "name": "Pad",
	#     "scene_file_path": "scenes/components/level_components/pads/Pad.tscn",
	#     "children_hsv": [],
	#     "has_physics": false,
	#     "has_texture_override": false,
	# },
}

const DEFAULT_PHYSICS := {
	"absorbent": false,
	"angular_velocity": 0.0,
	"bounce": 0.0,
	"friction": 1.0,
	"gravity_scale": 1.0,
	"linear_velocity": [0.0, 0.0],
	"mass": 1.0,
	"physics_object": false,
	"pushable_by_player": true,
	"rough": false,
	"scale": [1.0, 1.0]
}

const DEFAULT_LEVEL_TEMPLATE := {
	"active_layer_idx": 0,
	"color_channels": [],
	"creation_date": 0,
	"creator": "Player",
	"default_background_color": 913375231,
	"default_ground_color": 457950463,
	"default_line_color": 4294967295,
	"description": "",
	"duration": 0.0,
	"enter_effect": 1,
	"flashing_lights": false,
	"game_version": "0.0.1",
	"is_editable": true,
	"name": "imported_level",
	"platformer": false,
	"player_data": {
		"groups": [],
		"hsv": {"alpha": 1.0, "hsv_shift": [0.0, 0.0, 0.0], "intensity": 1.0},
		"z_index": 0
	},
	"rating": -1,
	"song_path": "",
	"song_start_time": 0.0,
	"start_displayed_gamemode": 0,
	"start_freefly": true,
	"start_gameplay_rotation_degrees": 0.0,
	"start_gravity_flip": 1,
	"start_gravity_multiplier": 1.0,
	"start_internal_gamemode": 0,
	"start_position": [640.0, 861.0],
	"start_reverse": false,
	"start_speed": 1.0,
	"start_speed_preset": 2
}

func _ready() -> void:
	if !FileAccess.file_exists("res://src/testlevels/postConvertedLevel.json"):
		import_to_file("user://created_levels/levels/preConvertedLevel.json", "res://src/testlevels/postConvertedLevel.json")


## Convert file GD JSON và load vào game ngay lập tức.
func import_and_play(input_path: String, options: Dictionary = {}) -> void:
	var output_path := OUTPUT_DIR + input_path.get_file().get_basename() + "_converted.json"
	var err := import_to_file(input_path, output_path, options)
	if err != OK:
		return
	LevelManager.current_level_path = output_path
	print("[GDImporter] Level path set: ", output_path)
	import_finished.emit(output_path)


## Convert file GD JSON và lưu ra file level JSON.
func import_to_file(input_path: String, output_path: String, options: Dictionary = {}) -> Error:
	# --- Đọc file ---
	if not FileAccess.file_exists(input_path):
		var msg := "[GDImporter] File không tìm thấy: " + input_path
		push_error(msg)
		import_failed.emit(msg)
		return ERR_FILE_NOT_FOUND

	var file := FileAccess.open(input_path, FileAccess.READ)
	if file == null:
		var msg := "[GDImporter] Không mở được file: " + input_path
		push_error(msg)
		import_failed.emit(msg)
		return ERR_CANT_OPEN

	var json_string := file.get_as_text()
	file.close()

	# --- Parse JSON ---
	var json := JSON.new()
	if json.parse(json_string) != OK:
		var msg := "[GDImporter] JSON lỗi dòng %d: %s" % [json.get_error_line(), json.get_error_message()]
		push_error(msg)
		import_failed.emit(msg)
		return ERR_PARSE_ERROR

	var data = json.data
	if data is not Dictionary:
		var msg := "[GDImporter] JSON phải là object"
		push_error(msg)
		import_failed.emit(msg)
		return ERR_INVALID_DATA

	# --- Convert từng section ---
	var objects: Array = []
	var counts: Dictionary = {}

	for section_key in OBJECT_REGISTRY:
		if not data.has(section_key):
			continue
		var section: Dictionary = data[section_key]
		var config: Dictionary  = OBJECT_REGISTRY[section_key]
		var n := 0
		for _id in section:
			objects.append(_make_object(section[_id], config))
			n += 1
		counts[section_key] = n

	# Fallback: file phẳng không có section key
	if objects.is_empty() and not data.is_empty():
		var first = data.values()[0]
		if first is Dictionary and first.has("x"):
			var config: Dictionary = OBJECT_REGISTRY["square"]
			for _id in data:
				objects.append(_make_object(data[_id], config))
			counts["square"] = objects.size()

	if objects.is_empty():
		var msg := "[GDImporter] Không có object nào trong file"
		push_warning(msg)
		import_failed.emit(msg)
		return ERR_INVALID_DATA

	# Log từng loại
	for k in counts:
		print("[GDImporter]   %s: %d" % [k, counts[k]])
	print("[GDImporter] Tổng: %d objects" % objects.size())

	# --- Build level ---
	var level_data: Dictionary = DEFAULT_LEVEL_TEMPLATE.duplicate(true)
	level_data["name"]          = input_path.get_file().get_basename()
	level_data["creation_date"] = int(Time.get_unix_time_from_system())
	level_data["layers"]        = [{"name": "Imported Layer", "objects": objects}]
	for key in options:
		level_data[key] = options[key]

	# --- Ghi file ---
	if not DirAccess.dir_exists_absolute(output_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())

	var out_file := FileAccess.open(output_path, FileAccess.WRITE)
	if out_file == null:
		var msg := "[GDImporter] Không ghi được file: " + output_path
		push_error(msg)
		import_failed.emit(msg)
		return ERR_CANT_CREATE

	out_file.store_string(JSON.stringify(level_data, "\t"))
	out_file.close()
	print("[GDImporter] Đã lưu: ", output_path)
	return OK


## Tạo 1 Godot object từ 1 GD entry + config từ OBJECT_REGISTRY.
func _make_object(sq: Dictionary, config: Dictionary) -> Dictionary:
	var ox: float = float(sq.x) * CELL_SIZE
	var oy: float = float(sq.y) * -CELL_SIZE - (CELL_SIZE / 2.0)
	var z:  int   = int(float(sq.z))

	var obj := {
		"children_hsv":  config["children_hsv"].duplicate(true),
		"color_channels": {},
		"groups":        [],
		"hsv":           {"alpha": 1.0, "hsv_shift": [0.0, 0.0, 0.0], "intensity": 1.0},
		"name":          config["name"],
		"scene_file_path": config["scene_file_path"],
		"transform": {
			"origin": [ox, oy],
			"x": [1.0, 0.0],
			"y": [0.0, 1.0]
		},
		"z_index": z
	}

	if config.get("has_physics", false):
		obj["physics"] = DEFAULT_PHYSICS.duplicate(true)

	if config.get("has_texture_override", false):
		obj["texture_override"] = config["texture_override"].duplicate(true)

	return obj
