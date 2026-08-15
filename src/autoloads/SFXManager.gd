extends Node

func play_sfx(sfx_path: String, bus_name: StringName = &"Game SFX") -> void:
	var sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.stream = load(sfx_path)
	sfx_player.set_bus(bus_name)
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()
