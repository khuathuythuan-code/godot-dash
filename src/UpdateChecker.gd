extends Button

@export var http: HTTPRequest
var out_of_date: bool = false


func _ready() -> void:
	http.connect("request_completed", _on_request_completed)
	http.request("https://codeberg.org/godot-dash/godot-dash/raw/branch/master/project.godot")
	text = "Checking for updates..."


func _on_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if body.get_string_from_utf8().containsn('config/version="' + ProjectSettings.get_setting("application/config/version") + '"'):
		text = "Up to date."
		await get_tree().create_timer(1.0).timeout
		var tween := create_tween().tween_property(self, "modulate:a", 0, 1).set_trans(Tween.TRANS_QUINT)
		await tween.finished
		hide()
		return
	text = "New update available! Click to download."
	out_of_date = true


func _on_pressed() -> void:
	if out_of_date:
		OS.shell_open("https://codeberg.org/godot-dash/godot-dash/")
		text = "Link opened."
		await get_tree().create_timer(5.0).timeout
		create_tween().tween_property(self, "modulate:a", 0, 1).set_trans(Tween.TRANS_QUINT)
