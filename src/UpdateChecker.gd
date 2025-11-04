extends Button

@export var http: HTTPRequest
var out_of_date: bool = false


func _ready() -> void:
	http.connect("request_completed", _on_request_completed)
	http.request("https://codeberg.org/godot-dash/godot-dash/raw/branch/master/project.godot")
	text = "Checking for updates..."


func _on_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if body.get_string_from_utf8().containsn('config/version="%s"' % ProjectSettings.get_setting("application/config/version")):
		text = "Up to date (version %s)." % ProjectSettings.get_setting("application/config/version")
		await get_tree().create_timer(1.0).timeout
		await create_tween().tween_property(self, "modulate:a", 0, 1).set_trans(Tween.TRANS_QUINT).finished
		hide()
		return
	var new_version: String
	for line in body.get_string_from_utf8().split("\n"):
		if line.begins_with("config/version="):
			new_version = line.replacen("config/version=", "").remove_chars('"')
			break
	text = "New update available (version %s)! Click to download." %  new_version
	out_of_date = true


func _on_pressed() -> void:
	if out_of_date:
		OS.shell_open("https://codeberg.org/godot-dash/godot-dash/")
		text = "Link opened."
		await get_tree().create_timer(5.0).timeout
		await create_tween().tween_property(self, "modulate:a", 0, 1).set_trans(Tween.TRANS_QUINT).finished
		hide()
