extends Object

class_name IconUtils

static func load_external_image(path: String) -> Texture2D:
	var image := Image.load_from_file(path)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func load_icon(path: String) -> Texture2D:
	if DirAccess.dir_exists_absolute(path) == false and FileAccess.file_exists(path) == false:
		Toasts.error("texture not found at path: " + path)
		return
	if path.contains("res://"):
		return load(path)
	else:
		return load_external_image(path)
