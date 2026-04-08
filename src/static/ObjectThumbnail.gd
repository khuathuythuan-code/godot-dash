@abstract
class_name ObjectThumbnail

static func get_object_sprite_images(object: Node2D) -> Array[Image]:
	const REBOUND_ORB_TEXTURE: Texture2D = preload("res://assets/textures/guis/editor/block_palette/ReboundOrbPreview.svg")
	const REBOUND_PAD_TEXTURE: Texture2D = preload("res://assets/textures/guis/editor/block_palette/ReboundPadPreview.svg")
	var images: Array[Image]
	for child: Node in object.get_children():
		if (child is Sprite2D or child is NinePatchSprite2D) and child.texture:
			images.append(child.texture.get_image())
		elif child is ReboundOrbSprite:
			images.append(REBOUND_ORB_TEXTURE.get_image())
		elif child is ReboundPadSprite:
			images.append(REBOUND_PAD_TEXTURE.get_image())
		elif child is LayeredSprite:
			images.append(child.get_composite_image())
	return images


## Generate a square thumbnail of the object (FIT_HEIGHT).
static func generate(object: Node2D, side_length: int) -> ImageTexture:
	var images: Array[Image] = get_object_sprite_images(object)
	for image: Image in images:
		image.resize((image.get_width() * side_length) / image.get_height(), side_length, Image.Interpolation.INTERPOLATE_LANCZOS)
	var composite_image: Image = Image.create_empty(side_length, side_length, false, Image.FORMAT_RGBA8)
	var composite_image_size: Vector2i = Vector2i.ONE * side_length
	for image: Image in images:
		var image_rect: Rect2i = Rect2i(Vector2i.ZERO, image.get_size())
		composite_image.blend_rect(image, image_rect, (composite_image_size - image.get_size()) / 2.0)
	return ImageTexture.create_from_image(composite_image)
