@tool
extends BoxContainer
class_name PreviewIcon

enum Icon {
	CUBE,
	SHIP,
	JETPACK,
	UFO,
	BALL,
	WAVE,
	ROBOT,
	SPIDER,
	SWING,
	TRAIL,
	DEATH_EFFECT,
}

@export var gamemode: Icon = Icon.CUBE
@export var icon_path: String = ""
@export var icon_scale: float = 1.0

func _ready() -> void:
	_refresh()


func _refresh() -> void:
	match gamemode:
		Icon.CUBE, Icon.SHIP, Icon.JETPACK, Icon.UFO, Icon.BALL, Icon.ROBOT:
			$Sprite.show()
			$Sprite.texture = ResourceLoader.load(icon_path)
		Icon.WAVE:
			$Sprite.show()
			$Sprite.texture = ResourceLoader.load(icon_path.path_join("Wave.svg"))
		Icon.SWING:
			$Sprite.show()
			$Sprite.texture = ResourceLoader.load(icon_path.path_join("Swing.svg"))
		Icon.DEATH_EFFECT:
			$Sprite.show()
			$Sprite.texture = ResourceLoader.load(icon_path.path_join("DeathEffect1.svg"))
		Icon.SPIDER:
			$Spider.show()
			var head_sprite := ResourceLoader.load(icon_path.path_join("Spider_Head.svg"))
			var head_glow_sprite := ResourceLoader.load(icon_path.path_join("Spider_Head-glow.svg"))
			var leg_sprite := ResourceLoader.load(icon_path.path_join("Spider_Leg.svg"))
			var leg_glow_sprite := ResourceLoader.load(icon_path.path_join("Spider_Leg-glow.svg"))
			for part in $Spider/Spider.get_children():
				if part.name == "Head":
					part.get_node(^"Spider").texture = head_sprite
					part.get_node(^"SpiderHead-glow").texture = head_glow_sprite
					continue
				part.get_node(^"SpiderLeg").texture = leg_sprite
				part.get_node(^"SpiderLeg-glow").texture = leg_glow_sprite
			$Spider/Spider.scale *= icon_scale
