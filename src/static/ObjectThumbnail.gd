@abstract
class_name ObjectThumbnail

static func get_object_thumbnail_image(object: Node2D) -> Array[Image]:
	const REBOUND_ORB_TEXTURE: Texture2D = preload("res://assets/textures/guis/editor/block_palette/ReboundOrbPreview.svg")
	const REBOUND_PAD_TEXTURE: Texture2D = preload("res://assets/textures/guis/editor/block_palette/ReboundPadPreview.svg")
	const TEXT_TEXTURE: Texture2D = preload("res://assets/textures/Text.svg")
	var images: Array[Image]
	for child: Node in object.get_children():
		if child is TriggerSprite:
			images.append(crop_image_around_center(child.texture.get_image(), 0.5))
		elif child is Label:
			images.append(crop_image_around_center(TEXT_TEXTURE.get_image(), 0.7))
		elif child is ReboundOrbSprite:
			images.append(REBOUND_ORB_TEXTURE.get_image())
		elif child is ReboundPadSprite:
			images.append(REBOUND_PAD_TEXTURE.get_image())
		elif child is LayeredSprite:
			images.append(child.get_composite_image())
		elif (child is Sprite2D or child is NinePatchSprite2D) and child.texture:
			images.append(child.texture.get_image())
		elif child is CanvasGroup:
			images.append_array(get_object_thumbnail_image(child))
	return images


static func crop_image_around_center(image: Image, size_factor: float) -> Image:
	# Shift image to prepare for crop
	var shift_factor: float = (1 - size_factor) / 2.0
	var rect: Rect2i = Rect2i(Vector2i.ZERO, image.get_size())
	image.blit_rect(image, rect, -image.get_size() * shift_factor)
	image.crop(roundi(image.get_width() * size_factor), roundi(image.get_height() * size_factor))
	return image


static func fit_size_to_square(size: Vector2i, side_length: int) -> Vector2i:
	var new_size: Vector2i = Vector2i.ONE * side_length
	if size.x < size.y: # Fit height
		new_size.x = roundi(float(size.x * side_length) / float(size.y))
	else: # Fit width
		new_size.y = roundi(float(size.y * side_length) / float(size.x))
	return new_size


## Generate a square thumbnail of the object.
static func generate(object: Node2D, side_length: int) -> ImageTexture:
	var images: Array[Image] = get_object_thumbnail_image(object)
	for image: Image in images:
		var image_size: Vector2i = fit_size_to_square(image.get_size(), side_length)
		image.resize(image_size.x, image_size.y, Image.Interpolation.INTERPOLATE_LANCZOS)
	var composite_image: Image = Image.create_empty(side_length, side_length, false, Image.FORMAT_RGBA8)
	var composite_image_size: Vector2i = Vector2i.ONE * side_length
	for image: Image in images:
		var image_rect: Rect2i = Rect2i(Vector2i.ZERO, image.get_size())
		composite_image.blend_rect(image, image_rect, (composite_image_size - image.get_size()) / 2.0)
	return ImageTexture.create_from_image(composite_image)
