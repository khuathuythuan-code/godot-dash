extends Node
class_name DiscordRPCHandler


static func _get_rpc():
	if OS.get_name() == "Web":
		return null

	if OS.get_name() == "Android":
		return null

	if not Engine.has_singleton("DiscordRPC"):
		return null

	return Engine.get_singleton("DiscordRPC")


static func set_app_id(id: int) -> void:
	var DiscordRPC = _get_rpc()

	if DiscordRPC == null:
		return

	DiscordRPC.app_id = id


static func set_large_image(image: String) -> void:
	var DiscordRPC = _get_rpc()

	if DiscordRPC == null:
		return

	DiscordRPC.large_image = image


static func set_start_timestamp(timestamp: int) -> void:
	var DiscordRPC = _get_rpc()

	if DiscordRPC == null:
		return

	DiscordRPC.start_timestamp = timestamp


static func set_details(details: String) -> void:
	var DiscordRPC = _get_rpc()

	if DiscordRPC == null:
		return

	DiscordRPC.details = details


static func run_callbacks() -> void:
	var DiscordRPC = _get_rpc()

	if DiscordRPC == null:
		return

	DiscordRPC.run_callbacks()


static func refresh() -> void:
	var DiscordRPC = _get_rpc()

	if DiscordRPC == null:
		return

	DiscordRPC.refresh()


static func clear() -> void:
	var DiscordRPC = _get_rpc()

	if DiscordRPC == null:
		return

	DiscordRPC.clear()


static func unclear() -> void:
	var DiscordRPC = _get_rpc()

	if DiscordRPC == null:
		return

	DiscordRPC.unclear()
