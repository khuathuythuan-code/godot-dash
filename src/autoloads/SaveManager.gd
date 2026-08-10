extends Node

const SAVE_FILE_PATH = "user://game_save.cfg"

# Dictionary holding level records: { level_name: { "attempt": int, "time": float, "jump": int, "completion": float } }
var level_records: Dictionary = {}

func _ready() -> void:
	load_game_data()

# Hàm lưu dữ liệu
func save_game_data() -> void:
	var config = ConfigFile.new()
	
	for lvl in level_records.keys():
		var data = level_records[lvl]
		config.set_value(lvl, "attempt", data.get("attempt", 0))
		config.set_value(lvl, "time", data.get("time", 0.0))
		config.set_value(lvl, "jump", data.get("jump", 0))
		config.set_value(lvl, "completion", data.get("completion", 0.0))
	
	var error = config.save(SAVE_FILE_PATH)
	if error == OK:
		print("Đã lưu dữ liệu thành công!")
	else:
		print("Lỗi lưu file: ", error)

# Hàm tải dữ liệu
func load_game_data() -> void:
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	
	level_records.clear()
	if error == OK:
		var sections = config.get_sections()
		for sec in sections:
			var attempt = config.get_value(sec, "attempt", 0)
			var time = config.get_value(sec, "time", 0.0)
			var jump = config.get_value(sec, "jump", 0)
			var completion = config.get_value(sec, "completion", 0.0)
			level_records[sec] = {
				"attempt": attempt,
				"time": time,
				"jump": jump,
				"completion": completion
			}
		print("Đã tải dữ liệu thành công! ", level_records)
	else:
		print("Chưa có file lưu, sử dụng dữ liệu mặc định.")

func get_best_record(level_name: String) -> Dictionary:
	if level_records.has(level_name):
		return level_records[level_name]
	return {
		"attempt": 0,
		"time": 0.0,
		"jump": 0,
		"completion": 0.0
	}

func compare_and_save_best_records(level_name: String, new_attempt: int, new_time: float, new_jump: int) -> void:
	var is_new_best := false
	
	var best = get_best_record(level_name)
	var best_attempt = best["attempt"]
	var best_time = best["time"]
	var best_jump = best["jump"]
	
	# Kiểm tra lần chơi đầu tiên (nếu kỷ lục cũ chưa có)
	if best_attempt == 0 or best_time == 0.0:
		is_new_best = true
	# 1. So sánh số lần thử (càng ít càng tốt)
	elif new_attempt < best_attempt:
		is_new_best = true
	# 2. Nếu số lần thử bằng nhau, so sánh thời gian (càng nhanh càng tốt)
	elif new_attempt == best_attempt:
		if new_time < best_time:
			is_new_best = true
		# 3. Nếu thời gian bằng nhau, so sánh lượt nhảy (càng ít càng tốt)
		elif new_time == best_time:
			if new_jump < best_jump:
				is_new_best = true
				
	# Nếu đạt kỷ lục mới thì cập nhật và lưu xuống file
	if is_new_best:
		level_records[level_name] = {
			"attempt": new_attempt,
			"time": new_time,
			"jump": new_jump,
			"completion": 100.0
		}
		save_game_data()
		
		
func compare_best_completion_and_save_attempt(level_name: String, new_completion: float, new_attempt: int) -> void:
	var best = get_best_record(level_name)
	var best_completion = best["completion"]
	var best_attempt = best["attempt"]

	var is_updated := false

	# Trường hợp 1: Tỷ lệ hoàn thành mới cao hơn tỷ lệ cũ
	if new_completion > best_completion:
		level_records[level_name] = {
			"attempt": new_attempt,
			"completion": new_completion,
			"time": best["time"],   # Giữ lại thời gian cũ
			"jump": best["jump"]     # Giữ lại số lượt nhảy cũ
		}
		is_updated = true
		
	# Trường hợp 2: Tỷ lệ hoàn thành bằng nhau, chọn lần hoàn thành có số lần thử ít hơn (tốt hơn)
	elif new_completion == best_completion:
		# (best_attempt == 0 là để phòng trường hợp lần đầu ghi dữ liệu)
		if new_attempt < best_attempt or best_attempt == 0:
			level_records[level_name] = {
				"attempt": new_attempt,
				"completion": best_completion,
				"time": best["time"],
				"jump": best["jump"]
			}
			is_updated = true

	# Chỉ lưu file khi thực sự có cập nhật kỷ lục mới
	if is_updated:
		save_game_data()
		
		
func update_and_save_best_record(level_name: String, new_completion: float, new_attempt: int, new_time: float, new_jump: int) -> void:
	var record = get_best_record(level_name).duplicate()
	var best_comp = record.get("completion", 0.0)
	var best_att = record.get("attempt", 0)
	var best_time = record.get("time", 0.0)
	var best_jump = record.get("jump", 0)

	var is_improved := false

	# 1. Đạt tỷ lệ hoàn thành cao hơn
	if new_completion > best_comp:
		is_improved = true
		record["completion"] = new_completion
		record["attempt"] = new_attempt
		record["time"] = new_time
		record["jump"] = new_jump

	# 2. Tỷ lệ hoàn thành bằng nhau
	elif new_completion == best_comp:
		# So sánh nhanh chóng 3 chỉ số theo thứ tự ưu tiên bằng Array Comparison
		if best_att == 0 or best_time == 0.0 or [new_attempt, new_time, new_jump] < [best_att, best_time, best_jump]:
			is_improved = true
			record["attempt"] = new_attempt
			record["time"] = new_time
			record["jump"] = new_jump

	if is_improved:
		level_records[level_name] = record
		save_game_data()
