@abstract
class_name StringUtils

static func pluralize(string: String, count: int) -> String:
	if count <= 1:
		return string
	return string + "s"
