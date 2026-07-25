extends Node

var available: bool = true


func _ready() -> void:
	available = false
	return


func  _process(_delta) -> void:
	if Config.discord_rich_presence and available:
		DiscordRPCHandler.run_callbacks()
