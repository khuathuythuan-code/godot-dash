class_name NinePatchSprite2DAbsoluteSize
extends Node

@export var nine_patch_sprite: NinePatchSprite2D
@onready var parent := get_parent() as Node2D



func _ready() -> void:
	update_size()
func update_size() -> void:
	nine_patch_sprite.global_scale = Vector2(0.25, 0.25)
	nine_patch_sprite.size = abs(parent.global_scale) * Vector2(512, 512)
	var scale_factor := Vector2(0.25, 0.25)
	var design_size := Vector2(512, 512)
	
	if parent and parent.has_meta(Constants.TEXTURE_OVERRIDE_META):
		var metadata = parent.get_meta(Constants.TEXTURE_OVERRIDE_META)
		if metadata is Dictionary and metadata.has("scale_factor"):
			var sf = metadata["scale_factor"]
			if sf is Array and sf.size() == 2:
				scale_factor = Vector2(sf[0], sf[1])
			elif sf is Vector2:
				scale_factor = sf
			if scale_factor.x != 0 and scale_factor.y != 0:
				design_size = Vector2.ONE * Constants.CELL_SIZE / scale_factor
	if parent:
		for child in parent.get_children():
			if child is NinePatchSprite2D:
				child.global_scale = scale_factor
				child.size = abs(parent.global_scale) * design_size
