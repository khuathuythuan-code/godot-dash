@abstract
class_name PropertyGenerator

static func from_property_list_field(type: Variant.Type, field: Dictionary) -> Property:
	var property: Property
	match type:
		TYPE_INT:
			match field.hint:
				PROPERTY_HINT_ENUM:
					var fields: PackedStringArray = field.hint_string.split(",")
					if fields.size() > 3:
						property = EnumProperty.new()
					else:
						property = OneLineEnumProperty.new()
					var prefix: String = "%s " % field.class_name.capitalize()
					property.fields = fields
					for i in property.fields.size():
						var enum_variant_name: String = property.fields[i].get_slice(":", 0).trim_prefix(prefix)
						property.fields.set(i, enum_variant_name)
				PROPERTY_HINT_FLAGS:
					property = FlagsProperty.new()
					property.flags = field.hint_string.split(",")
					for i in property.flags.size():
						property.flags.set(i, property.flags[i].get_slice(":", 0))
				_:
					property = FloatProperty.new()
					property.allow_lesser = true
					property.allow_greater = true
					property.rounded = true
					property.step = 1.0
		TYPE_FLOAT:
			if "slider" in field.hint_string:
				property = FloatSliderProperty.new()
			else:
				property = FloatProperty.new()
			if field.hint == PROPERTY_HINT_NONE:
				property.allow_lesser = true
				property.allow_greater = true
			elif field.hint == PROPERTY_HINT_RANGE:
				property = handle_range_hint(field, property)
		TYPE_STRING, TYPE_STRING_NAME:
			if field.hint == PROPERTY_HINT_GLOBAL_FILE:
				property = FileProperty.new()
				var split_hint_string := Array(field.hint_string.split(","))
				if "load_root" in field.hint_string:
					property.load_root = split_hint_string[split_hint_string.find("load_root")].trim_prefix("load_root:")
					# split_hint_string.pop_at(split_hint_string.find("load_root"))
				if "import_to" in field.hint_string:
					property.load_root = split_hint_string[split_hint_string.find("import_to")].trim_prefix("import_to:")
					# split_hint_string.pop_at(split_hint_string.find("import_to"))
				property.filetype_filters = PackedStringArray(split_hint_string)
			elif field.hint == PROPERTY_HINT_MULTILINE_TEXT:
				property = MultilineStringProperty.new()
			else:
				property = StringProperty.new()
				property.placeholder = field.hint_string
		TYPE_NODE_PATH:
			property = NodeProperty.new()
		TYPE_COLOR:
			property = ColorProperty.new()
		TYPE_VECTOR2:
			property = Vector2Property.new()
			if field.hint == PROPERTY_HINT_NONE:
				property.allow_lesser = true
				property.allow_greater = true
				if "suffix" in field.hint_string:
					property.suffix = field.hint_string.trim_prefix("suffix:")
			elif field.hint == PROPERTY_HINT_RANGE:
				property = handle_range_hint(field, property)
		TYPE_BOOL:
			property = BoolProperty.new()
		TYPE_OBJECT:
			match field.hint:
				PROPERTY_HINT_RESOURCE_TYPE:
					property = load("res://scenes/components/game_components/resource_properties/" + field.hint_string + "Property.tscn").instantiate()
		TYPE_ARRAY:
			property = ArrayProperty.new()
			var hint_string: String = field.hint_string
			var array_type := int(hint_string.get_slice("/", 0))
			var array_hint := int(hint_string.get_slice("/", 1))
			var array_hint_string: String = hint_string.get_slice(":", 1)
			var packed := PackedScene.new()
			# TODO: handle other typed arrays
			if array_type == TYPE_OBJECT and array_hint == PROPERTY_HINT_RESOURCE_TYPE:
				packed = load("res://scenes/components/game_components/resource_properties/" + array_hint_string + "Property.tscn")
			property.item_template = packed
	assert(property != null)
	return property


static func handle_range_hint(field: Dictionary, property: Property) -> Property:
	var hint_string: String = field.hint_string
	var split_hint_string := Array(hint_string.split(","))
	var min_value = split_hint_string[0]
	var max_value = split_hint_string[1]
	var step = split_hint_string[2]
	property.min_value = min_value
	property.max_value = max_value
	property.step = step
	if "or_greater" in hint_string:
		property.allow_greater = true
	if "or_less" in hint_string:
		property.allow_lesser = true
	if "degrees" in hint_string:
		property.suffix = "°"
	if "suffix" in hint_string:
		property.suffix = split_hint_string[split_hint_string.find("suffix")].trim_prefix("suffix:")
	return property
