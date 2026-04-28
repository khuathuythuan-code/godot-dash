## GDImporter.gd
## Autoload: chuyển file square JSON (Geometry Dash export) thành level JSON của game.
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

# Khớp với Constants.gd
const CELL_SIZE: int = 128
const OUTPUT_DIR: String = Constants.LEVEL_DIR

# Template mặc định cho level — có thể override qua tham số options
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

const DEFAULT_OBJECT_TEMPLATE := {
	"scene_file_path": "scenes/components/level_components/solids/NinePatchBlock.tscn",
	"name": "RegularBlock01",
	"texture_override": {
		"base": "assets/textures/solids/regular_blocks/RegularBlock01.svg",
		"id": 0
	},
	"children_hsv": [
		{"alpha": 1.0, "hsv_shift": [0.0, 0.0, 0.0], "intensity": 1.0},
		{"alpha": 1.0, "hsv_shift": [0.0, 0.0, 0.0], "intensity": 1.0}
	],
	"color_channels": {},
	"groups": [],
	"hsv": {"alpha": 1.0, "hsv_shift": [0.0, 0.0, 0.0], "intensity": 1.0},
	"physics": {
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
	},
	"transform": {
		"origin": [0.0, 0.0],
		"x": [1.0, 0.0],
		"y": [0.0, 1.0]
	},
	"z_index": 0
}

func _ready() -> void:
	if FileAccess.file_exists("res://src/testlevels/postConvertedLevel.json"):
		print("File tồn tại")
	else:
		import_to_file("user://created_levels/levels/preConvertedLevel.json","res://src/testlevels/postConvertedLevel.json")


## Convert file square JSON và load vào game ngay lập tức.
## [param input_path] đường dẫn tới file square JSON
## [param options] Dictionary để override các field của level (tuỳ chọn)
func import_and_play(input_path: String, options: Dictionary = {}) -> void:
	var output_path := OUTPUT_DIR + input_path.get_file().get_basename() + "_converted.json"
	var err := import_to_file(input_path, output_path, options)
	if err != OK:
		return
	LevelManager.current_level_path = output_path
	print("[GDImporter] Level path set: ", output_path)
	import_finished.emit(output_path)


## Convert file square JSON và lưu ra file level JSON.
## Trả về Error code (OK = thành công).
func import_to_file(input_path: String, output_path: String, options: Dictionary = {}) -> Error:
	# --- Đọc file input ---
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
		var msg := "[GDImporter] JSON phải là object, không phải array"
		push_error(msg)
		import_failed.emit(msg)
		return ERR_INVALID_DATA

	# --- Lấy square data (hỗ trợ cả 2 format) ---
	# Format 1: {"square": {...}}
	# Format 2: {"id": ..., "x": ..., "y": ..., "z": ...} trực tiếp
	var square_dict: Dictionary
	if data.has("square"):
		square_dict = data["square"]
	else:
		square_dict = data

	if square_dict.is_empty():
		var msg := "[GDImporter] Không có block nào trong file"
		push_warning(msg)
		import_failed.emit(msg)
		return ERR_INVALID_DATA

	# --- Convert blocks ---
	var objects := _convert_blocks(square_dict)
	print("[GDImporter] Converted %d blocks từ %s" % [objects.size(), input_path])

	# --- Build level JSON ---
	var level_data: Dictionary = DEFAULT_LEVEL_TEMPLATE.duplicate(true)
	level_data["name"] = input_path.get_file().get_basename()
	level_data["creation_date"] = int(Time.get_unix_time_from_system())
	level_data["layers"] = [{"name": "Imported Layer", "objects": objects}]

	# Override bất kỳ field nào từ options
	for key in options:
		level_data[key] = options[key]

	# --- Ghi file output ---
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


## Convert dictionary square blocks thành mảng object Godot.
func _convert_blocks(square_dict: Dictionary) -> Array:
	var objects := []
	for _key in square_dict:
		var sq: Dictionary = square_dict[_key]
		var obj: Dictionary = DEFAULT_OBJECT_TEMPLATE.duplicate(true)
		# Công thức từ Constants.CELLS_TO_PX = Vector2(128, -128)
		# origin_x = sq_x * 128
		# origin_y = sq_y * -128 - 64  (trừ 64 vì pivot ở tâm block 128px)
		var ox: float = float(sq.x) * CELL_SIZE
		var oy: float = float(sq.y) * -CELL_SIZE - (CELL_SIZE / 2.0)
		var z: int   = int(sq.z)

		obj["transform"] = {
			"origin": [ox, oy],
			"x": [1.0, 0.0],
			"y": [0.0, 1.0]
		}
		obj["z_index"] = z
		objects.append(obj)

	return objects
