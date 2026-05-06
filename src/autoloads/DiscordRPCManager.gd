extends Node

var available: bool = true


func _ready() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "Web":
		available = false
		return

	DiscordRPCHandler.set_app_id(1434298571733078136)
	DiscordRPCHandler.set_large_image("large_image")
	DiscordRPCHandler.set_start_timestamp(int(Time.get_unix_time_from_system()))


func  _process(_delta) -> void:
	if Config.discord_rich_presence and available:
		DiscordRPCHandler.run_callbacks()
