extends Button

var version: String = ProjectSettings.get_setting("application/config/version")
var out_of_date: bool = false
var new_version: String


func _ready() -> void:
	if not Config.check_for_updates:
		text = version
		return
	pressed.connect(_on_pressed)
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	http.request("https://codeberg.org/godot-dash/godot-dash/raw/branch/master/project.godot")
	text = "(v%s) Checking for updates..." % version


func _on_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if not body.get_string_from_utf8().containsn('config/version='):
		text = "(v%s) Could not check for updates." % version
		add_theme_color_override("font_disabled_color", Color.DARK_RED)
		return
	elif body.get_string_from_utf8().containsn('config/version="%s"' % version):
		text = "(v%s) Up to date." % version
		return
	for line in body.get_string_from_utf8().split("\n"):
		if line.begins_with("config/version="):
			new_version = line.replacen("config/version=", "").remove_chars('"')
			break
	text = "(v%s) New update available: v%s! Click to download." % [version, new_version]
	disabled = false


func _on_pressed() -> void:
	OS.shell_open("https://codeberg.org/godot-dash/godot-dash/")
	text = "Link opened!"
	await get_tree().create_timer(1.0).timeout
	text = "(v%s) New update available: v%s! Click to download." % [version, new_version]
