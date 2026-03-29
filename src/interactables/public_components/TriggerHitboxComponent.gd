class_name TriggerHitboxComponent
extends Component

enum HitboxShape {
	LINE,
	SQUARE,
	DISABLED,
}

@export var _hitbox: CollisionShape2D
@export var hitbox_shape: HitboxShape:
	set(value):
		hitbox_shape = value
		if _hitbox == null:
			return
		match value:
			HitboxShape.LINE:
				_hitbox.shape = SegmentShape2D.new()
				_hitbox.shape.a = Vector2(0, -hitbox_height * Constants.CELL_SIZE)
				_hitbox.shape.b = Vector2(0, hitbox_height * Constants.CELL_SIZE)
			HitboxShape.SQUARE:
				_hitbox.shape = RectangleShape2D.new()
				_hitbox.shape.size = Vector2.ONE * Constants.CELL_SIZE
			HitboxShape.DISABLED:
				_hitbox.shape = null

@export_range(0.01, 128.0, 0.01, "or_greater", "suffix:cells") var hitbox_height: float = 64.0:
	set(value):
		hitbox_height = value
		if hitbox_shape != HitboxShape.LINE or _hitbox == null:
			return
		_hitbox.shape = SegmentShape2D.new()
		_hitbox.shape.a = Vector2(0, -value * Constants.CELL_SIZE)
		_hitbox.shape.b = Vector2(0, value * Constants.CELL_SIZE)
