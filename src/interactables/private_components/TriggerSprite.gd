class_name TriggerSprite
extends Sprite2D

func get_cropped_image() -> Image:
	var image: Image = texture.get_image()
	# Shift image to prepare for crop
	var rect: Rect2i = Rect2i(Vector2i.ZERO, image.get_size())
	image.blit_rect(image, rect, -image.get_size() / 4.0)
	image.crop(roundi(image.get_width() / 2.0), roundi(image.get_height() / 2.0))
	return image
