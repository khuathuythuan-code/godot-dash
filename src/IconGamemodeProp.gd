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
	var icon_type: PreviewIcon.Icon = gamemode as int as PreviewIcon.Icon
	if icon_type == PreviewIcon.Icon.SHIP and platformer == PlatformerState.PLATFORMER_ONLY:
		icon_type = PreviewIcon.Icon.JETPACK
	match icon_type:
		PreviewIcon.Icon.SWING:
			$"SwingGlow".texture = IconUtils.load_icon(Config.icons[icon_type].path.path_join("SwingGlow.svg"))
			$"SwingNoGlow".texture = IconUtils.load_icon(Config.icons[icon_type].path.path_join("SwingNoGlow.svg"))
		PreviewIcon.Icon.SPIDER:
			var head_sprite: Texture2D = IconUtils.load_icon(Config.icons[icon_type].path.path_join("Spider_Head.svg"))
			var head_glow_sprite: Texture2D = IconUtils.load_icon(Config.icons[icon_type].path.path_join("Spider_Head-glow.svg"))
			var leg_sprite: Texture2D = IconUtils.load_icon(Config.icons[icon_type].path.path_join("Spider_Leg.svg"))
			var leg_glow_sprite: Texture2D = IconUtils.load_icon(Config.icons[icon_type].path.path_join("Spider_Leg-glow.svg"))
			for part in get_node(^"SpiderSprites").get_children():
				if not part is Marker2D:
					continue
				if part.name == "Head":
					part.get_node(^"Spider").texture = head_sprite
					part.get_node(^"SpiderHead-glow").texture = head_glow_sprite
					continue
				part.get_node(^"SpiderLeg").texture = leg_sprite
				part.get_node(^"SpiderLeg-glow").texture = leg_glow_sprite
		_:
			var icon: Texture2D = IconUtils.load_icon(Config.icons[icon_type].path)
			var sprite: Sprite2D = NodeUtils.get_child_of_type(self, Sprite2D)
			sprite.texture = icon
