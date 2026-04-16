extends Node
class_name DiscordRPCHandler


static func _is_available() -> bool:
	return OS.get_name() != "Web" and OS.get_name() != "Android"


static func set_app_id(id: int) -> void:
	if not _is_available():
		return
	DiscordRPC.app_id = id


static func set_large_image(image: String) -> void:
	if not _is_available():
		return
	DiscordRPC.large_image = image


static func set_start_timestamp(timestamp: int) -> void:
	if not _is_available():
		return
	DiscordRPC.start_timestamp = timestamp


static func set_details(details: String) -> void:
	if not _is_available():
		return
	DiscordRPC.details = details


static func run_callbacks() -> void:
	if not _is_available():
		return
	DiscordRPC.run_callbacks()


static func refresh() -> void:
	if not _is_available():
		return
	DiscordRPC.refresh()


static func clear() -> void:
	if not _is_available():
		return
	DiscordRPC.clear()


static func unclear() -> void:
	if not _is_available():
		return
	DiscordRPC.unclear()
