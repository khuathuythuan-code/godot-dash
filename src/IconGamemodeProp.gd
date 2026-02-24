extends Node2D

class_name IconGamemodeProp

enum PlatformerState {
	BOTH,
	SIDESCROLLER_ONLY,
	PLATFORMER_ONLY,
}

@export var gamemode: Player.Gamemode
@export var platformer: PlatformerState


func _ready() -> void:
	var icon_type = gamemode as int
	icon_type = icon_type as PreviewIcon.Icon
	if icon_type == PreviewIcon.Icon.SHIP and platformer == PlatformerState.PLATFORMER_ONLY:
		icon_type = PreviewIcon.Icon.JETPACK
	match icon_type:
		PreviewIcon.Icon.CUBE, PreviewIcon.Icon.BALL, PreviewIcon.Icon.UFO, PreviewIcon.Icon.SHIP, PreviewIcon.Icon.JETPACK:
			var icon: Texture2D = load(Config.icons[icon_type]["path"])
			for child in get_children():
				if child is Sprite2D:
					child.texture = icon
					break
		PreviewIcon.Icon.WAVE:
			var icon: Texture2D = load(Config.icons[icon_type]["path"].path_join("Wave.svg"))
			for child in get_children():
				if child is Sprite2D:
					child.texture = icon
					break
		PreviewIcon.Icon.SWING:
			var icon: Texture2D = load(Config.icons[icon_type]["path"].path_join("Swing.svg"))
			for child in get_children():
				if child is Sprite2D:
					child.texture = icon
					break
		PreviewIcon.Icon.SPIDER:
			var head_sprite: Texture2D = load(Config.icons[icon_type]["path"].path_join("Spider_Head.svg"))
			var head_glow_sprite: Texture2D = load(Config.icons[icon_type]["path"].path_join("Spider_Head-glow.svg"))
			var leg_sprite: Texture2D = load(Config.icons[icon_type]["path"].path_join("Spider_Leg.svg"))
			var leg_glow_sprite: Texture2D = load(Config.icons[icon_type]["path"].path_join("Spider_Leg-glow.svg"))
			for part in get_node(^"SpiderSprites").get_children():
				if not part is Marker2D:
					continue
				if part.name == "Head":
					part.get_node(^"Spider").texture = head_sprite
					part.get_node(^"SpiderHead-glow").texture = head_glow_sprite
					continue
				part.get_node(^"SpiderLeg").texture = leg_sprite
				part.get_node(^"SpiderLeg-glow").texture = leg_glow_sprite
