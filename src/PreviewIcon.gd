@tool
class_name PreviewIcon
extends CenterContainer

enum Icon {
	CUBE,
	SHIP,
	UFO,
	BALL,
	WAVE,
	ROBOT,
	SPIDER,
	SWING,
	JETPACK,
	TRAIL,
	DEATH_EFFECT,
}

@export var gamemode: Icon = Icon.CUBE
@export var icon_path: String = "":
	set(value):
		icon_path = value
		if is_node_ready():
			_refresh()
@export var icon_scale: float = 1.0
var last_position: Vector2


func _ready() -> void:
	_refresh()


func _process(_delta: float) -> void:
	if visible and gamemode == Icon.TRAIL:
		if last_position != global_position:
			_refresh()
		last_position = global_position
		$Trail/Trail.width = get_parent().scale.x * $Trail/Trail.texture.get_height()


func _refresh() -> void:
	match gamemode:
		Icon.SWING:
			$Sprite.show()
			$Sprite.texture = AssetManager.load_icon(icon_path.path_join("Swing.svg"), gamemode)
		Icon.DEATH_EFFECT:
			$"Death Effect".show()
			for icon in DirAccess.open(icon_path).get_files():
				if icon.contains(".import"):
					continue
				var frame: Texture2D = AssetManager.load_icon(icon_path + "/" + icon, gamemode)
				$"Death Effect/Death Effect".sprite_frames.add_frame(&"default", frame)
				$"Death Effect/Death Effect".scale = Vector2.ONE * 0.25 * icon_scale
				$"Death Effect/Death Effect".play(&"default")
		Icon.TRAIL:
			$Trail.show()
			$Trail/Trail.texture = AssetManager.load_icon(icon_path, gamemode)
			$Trail/Trail.width = $Trail/Trail.texture.get_height()
			$Trail/Trail.clear_points()
			$Trail/Trail.add_point(global_position + Vector2(2, custom_minimum_size.y / 2))
			$Trail/Trail.add_point(global_position + Vector2(custom_minimum_size.x, custom_minimum_size.y / 2))
		Icon.SPIDER:
			$Spider.show()
			var head_sprite: Texture2D = AssetManager.load_icon(icon_path.path_join("Spider_Head.svg"), gamemode)
			var head_glow_sprite: Texture2D = AssetManager.load_icon(icon_path.path_join("Spider_Head-glow.svg"), gamemode)
			var leg_sprite: Texture2D = AssetManager.load_icon(icon_path.path_join("Spider_Leg.svg"), gamemode)
			var leg_glow_sprite: Texture2D = AssetManager.load_icon(icon_path.path_join("Spider_Leg-glow.svg"), gamemode)
			for part in $Spider/Spider.get_children():
				if part.name == "Head":
					part.get_node(^"Spider").texture = head_sprite
					part.get_node(^"SpiderHead-glow").texture = head_glow_sprite
					continue
				part.get_node(^"SpiderLeg").texture = leg_sprite
				part.get_node(^"SpiderLeg-glow").texture = leg_glow_sprite
			$Spider/Spider.scale = Vector2.ONE * icon_scale
		_:
			$Sprite.show()
			$Sprite.texture = AssetManager.load_icon(icon_path, gamemode)
