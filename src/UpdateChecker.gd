extends Node

@export var http: HTTPRequest
var toast: Toast
var out_of_date: bool = false


func _ready() -> void:
	http.connect("request_completed", _on_request_completed)
	http.request("https://codeberg.org/godot-dash/godot-dash/raw/branch/master/project.godot")
	toast = Toasts.new_toast("Checking for updates...", INF)


func _on_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	var text: String
	if body.get_string_from_utf8().containsn('config/version="%s"' % ProjectSettings.get_setting("application/config/version")):
		text = "Up to date (version %s)." % ProjectSettings.get_setting("application/config/version")
		if toast:
			toast.text = text
		else:
			Toasts.new_toast(text, INF)
		await get_tree().create_timer(1.0).timeout
		if toast:
			toast.dismiss()
		return
	for line in body.get_string_from_utf8().split("\n"):
		if line.begins_with("config/version="):
			text = line.replacen("config/version=", "").remove_chars('"')
			break
	text = "New update available (version %s)! Click to download." % text
	if toast:
		toast.text = text
	else:
		Toasts.new_toast(text, INF)
	out_of_date = true
	toast.connect("pressed", _on_toast_pressed)


func _on_toast_pressed() -> void:
	if out_of_date:
		toast.text = "Link opened."
		OS.shell_open("https://codeberg.org/godot-dash/godot-dash/")
		await get_tree().create_timer(0.2).timeout
		queue_free()
