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


static func generate(object: Node2D, side_length: int) -> ImageTexture:
	var images: Array[Image] = get_object_sprite_images(object)
	for image: Image in images:
		image.resize((image.get_width() * side_length) / image.get_height(), side_length, Image.Interpolation.INTERPOLATE_LANCZOS)
	var composite_image: Image = images[0]
	var image_rect: Rect2i = Rect2i(Vector2i.ZERO, composite_image.get_size())
	for i: int in images.size():
		if i == 0:
			continue
		composite_image.blend_rect(images[i], image_rect, Vector2i.ZERO)
	return ImageTexture.create_from_image(composite_image)
