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
	var rpc = _get_rpc()

	if rpc == null:
		return

	rpc.app_id = id


static func set_large_image(image: String) -> void:
	var rpc = _get_rpc()

	if rpc == null:
		return

	rpc.large_image = image


static func set_start_timestamp(timestamp: int) -> void:
	var rpc = _get_rpc()

	if rpc == null:
		return

	rpc.start_timestamp = timestamp


static func set_details(details: String) -> void:
	var rpc = _get_rpc()

	if rpc == null:
		return

	rpc.details = details


static func run_callbacks() -> void:
	var rpc = _get_rpc()

	if rpc == null:
		return

	rpc.run_callbacks()


static func refresh() -> void:
	var rpc = _get_rpc()

	if rpc == null:
		return

	rpc.refresh()


static func clear() -> void:
	var rpc = _get_rpc()

	if rpc == null:
		return

	rpc.clear()


static func unclear() -> void:
	var rpc = _get_rpc()

	if rpc == null:
		return

	rpc.unclear()
