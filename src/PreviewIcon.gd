@tool
extends Control
class_name PreviewIcon

enum Gamemode {
	CUBE,
	SHIP,
	JETPACK,
	UFO,
	BALL,
	WAVE,
	ROBOT,
	SPIDER,
	SWING
}

@export var gamemode: Gamemode = Gamemode.CUBE
@export var icon_path: String = ""
@export var icon_scale: float = 1.0

func _ready() -> void:
	_refresh()


func _refresh() -> void:
	match gamemode:
		Gamemode.CUBE, Gamemode.SHIP, Gamemode.JETPACK, Gamemode.UFO, Gamemode.BALL, Gamemode.WAVE, Gamemode.ROBOT, Gamemode.SWING:
			var sprite := Sprite2D.new()
			sprite.texture = ResourceLoader.load(icon_path)
			sprite.scale = Vector2(0.25, 0.25) * icon_scale if not gamemode == Gamemode.SWING else Vector2.ONE * icon_scale
			add_child(sprite)
		Gamemode.SPIDER:
			$Spider.visible = true
			var head_sprite := ResourceLoader.load(icon_path + "Spider_Head.svg")
			var head_glow_sprite := ResourceLoader.load(icon_path + "Spider_Head-glow.svg")
			var leg_sprite := ResourceLoader.load(icon_path + "Spider_Leg.svg")
			var leg_glow_sprite := ResourceLoader.load(icon_path + "Spider_Leg-glow.svg")
			for part in $Spider.get_children():
				if part.name == "Head":
					part.get_node(^"Spider").texture = head_sprite
					part.get_node(^"SpiderHead-glow").texture = head_glow_sprite
					continue
				part.get_node(^"SpiderLeg").texture = leg_sprite
				part.get_node(^"SpiderLeg-glow").texture = leg_glow_sprite
			$Spider.scale *= icon_scale
