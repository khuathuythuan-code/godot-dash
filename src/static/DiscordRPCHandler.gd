extends Node
class_name DiscordRPCHandler


static func set_app_id(id: int) -> void:
	DiscordRPC.app_id = id


static func set_large_image(image: String) -> void:
	DiscordRPC.large_image = image


static func set_start_timestamp(timestamp: int) -> void:
	DiscordRPC.start_timestamp = timestamp


static func set_details(details: String) -> void:
	DiscordRPC.details = details


static func run_callbacks() -> void:
	DiscordRPC.run_callbacks()


static func refresh() -> void:
	DiscordRPC.refresh()


static func clear() -> void:
	DiscordRPC.clear()


static func unclear() -> void:
	DiscordRPC.unclear()
