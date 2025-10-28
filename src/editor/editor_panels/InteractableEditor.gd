extends Control
class_name InteractableEditor

# Scripts aren't constants but the array shouldn't be modified nontheless.
static var COMPONENT_BLACKLIST: Array[Script] = [
	JumpBoostComponent,
	GravityFlipChangerComponent,
	ReboundComponent,
	SpiderDashComponent,
	FireDashComponent,
	SpeedChangerComponent,
	# PlayerCountChangerComponent, # we need to be able to set if duals use the same gravity
	PlayerScaleChangerComponent,
	TextureRotationPinComponent,
	# Letter blocks
	StopHeldJumpComponent,
	StopDashComponent,
	FlipGravityComponent,
	AllowCeilingHitComponent,
	AllowWaveSlideComponent,
	HiddenOutsideEditorComponent,
]

# Querying this at runtime is overkill
static var MARKER_COMPONENTS: Array[Script] = [
	SingleUsageComponent,
	NoEffectsComponent,
]

@export var components_root: Container
@export var separator: HSeparator
@export var markers_root: Container

var marker_properties: Dictionary[Script, BoolProperty]


func _init() -> void:
	COMPONENT_BLACKLIST.append_array(MARKER_COMPONENTS)
	COMPONENT_BLACKLIST.make_read_only()
	MARKER_COMPONENTS.make_read_only()


func _ready() -> void:
	for marker in MARKER_COMPONENTS:
		var property := BoolProperty.new()
		property.name = marker.get_global_name().trim_suffix("Component").capitalize()
		marker_properties.set(marker, property)
		markers_root.add_child(property)


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	clear_ui()
	if selection.is_empty() or not selection.all(is_interactable):
		return
	var interactables: Array[Interactable]
	interactables.assign(selection)
	build_ui(interactables)


func clear_ui() -> void:
	components_root.get_children().map(func(child): child.queue_free())


func rebuild_ui(interactables: Array[Interactable]) -> void:
	clear_ui()
	build_ui(interactables)


func build_ui(interactables: Array[Interactable]) -> void:
	var first_interactable := interactables[0]
	var ui_root := VBoxContainer.new()
	var should_component_be_displayed := func(component):
		return (not component.get_script() in COMPONENT_BLACKLIST) and (not component.get_script() in MARKER_COMPONENTS)
	var displayed_components := first_interactable \
			.components \
			.filter(should_component_be_displayed)

	if displayed_components:
		for i in displayed_components.size():
			var component = displayed_components[i]
			NodeUtils.connect_once(component.property_list_changed, rebuild_ui.bind(interactables))
			var fields: Array[Dictionary] = component.script.get_script_property_list()
			# Follow _validate_property
			if component.has_method(&"_validate_property"):
				fields.map(func(field): component._validate_property(field))
			fields = fields \
					.filter(func(field): return field.usage & PROPERTY_USAGE_EDITOR or field.usage & PROPERTY_USAGE_GROUP)
			var last_section: FoldableContainer = null
			for field: Dictionary in fields:
				var field_name: String = field.name
				if field_name.begins_with("_"):
					continue
				if field.usage & PROPERTY_USAGE_GROUP:
					if last_section:
						ui_root.add_child(last_section)
						last_section.show.call_deferred()
					last_section = FoldableContainer.new()
					last_section.name = field_name
					last_section.title = field_name
					last_section.title_alignment = HORIZONTAL_ALIGNMENT_LEFT
					last_section.add_child(VBoxContainer.new())
					last_section.folded = true
					last_section.hide()
					continue
				var property: Property
				property = generate_property(field.type, field)
				property.name = field_name.capitalize()
				property.set_meta(&"component_name", component.name)
				property.set_input_state.call_deferred(not field.usage & PROPERTY_USAGE_READ_ONLY)
				if last_section:
					var section_vboxcontainer := last_section.get_child(0) as VBoxContainer
					section_vboxcontainer.add_child(property)
				else:
					ui_root.add_child(property)
			if last_section:
				ui_root.add_child(last_section)
				last_section.show.call_deferred()
			if i < displayed_components.size() - 1:
				ui_root.add_child(HSeparator.new())
		components_root.add_child(ui_root)
		components_root.visible = ui_root.get_child_count() > 0
		separator.visible = components_root.visible
	else:
		components_root.hide()
		separator.hide()

	connect_ui(interactables, self)
	load_properties.call_deferred(first_interactable, self)


func generate_property(variant_type: int, field: Dictionary) -> Property:
	var property: Property
	match variant_type:
		TYPE_INT:
			match field.hint:
				PROPERTY_HINT_ENUM:
					property = EnumProperty.new()
					var prefix: String = "%s " % field.class_name.capitalize()
					property.fields = field.hint_string.split(",")
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
			if field.hint == PROPERTY_HINT_NODE_TYPE and field.hint_string == "Node2D":
				property = Node2DProperty.new()
			if field.hint == PROPERTY_HINT_RESOURCE_TYPE:
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
	return property


func connect_ui(interactables: Array[Interactable], ui_root: Control) -> void:
	var properties := NodeUtils.get_children_of_type(ui_root, Property, true)
	if properties.is_empty():
		return
	for property in properties as Array[Property]:
		var remove_connections := func(connection):
			if not "watcher" in connection.callable.get_method():
				property.value_changed.disconnect(connection.callable)
		property.value_changed.get_connections().map(remove_connections)
		var property_name := property.name.to_snake_case()
		if property is BoolProperty and property in marker_properties.values():
			property.value_changed.connect(refresh_marker.bind(marker_properties.find_key(property), interactables))
			continue
		property.value_changed.connect(save_property.bind(property.get_meta(&"component_name"), property_name, interactables))


func save_property(value: Variant, component_name: String, property: String, interactables: Array[Interactable]) -> void:
	interactables.map(func(interactable):
		var _value = value
		if interactable.get_node(component_name) is TargetGroupComponent:
			_value = GroupEditor.GROUP_PREFIX + value
		interactable.get_node(component_name).set(property, _value))


func refresh_marker(enabled: bool, marker_script: Script, interactables: Array[Interactable]) -> void:
	for interactable in	interactables:
		if enabled:
			var marker: Marker = NodeUtils.get_node_or_add(interactable, str(marker_script.get_global_name()), marker_script, NodeUtils.SET_OWNER | NodeUtils.FORCE_READABLE_NAME)
			interactable.register_public(marker)
		else:
			NodeUtils.get_children_of_type(interactable, marker_script).map(func(marker):
				interactable.components.erase(marker)
				marker.queue_free())


func load_properties(interactable: Interactable, ui_root: Control) -> void:
	var properties := NodeUtils.get_children_of_type(ui_root, Property, true)
	if properties.is_empty():
		return
	for property in properties as Array[Property]:
		if property is BoolProperty and property in marker_properties.values():
			property.set_value_no_signal(interactable.has(marker_properties.find_key(property)))
			continue
		var property_name := property.name.to_snake_case()
		var component := interactable.get_node(str(property.get_meta(&"component_name")))
		if component == null or component.get(property_name) == null:
			printerr("Can't load property ", property_name, " on ", interactable)
			continue
		var value = component.get(property_name)
		if component is TargetGroupComponent:
			value = value.trim_prefix(GroupEditor.GROUP_PREFIX)
		property.set_value_no_signal(value)


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


static func is_interactable(object: Node2D) -> bool:
	return object is Interactable


static func same_script(object: Interactable, reference: Interactable) -> bool:
	return object.get_script() == reference.get_script()


static func same_components(object: Interactable, reference: Interactable) -> bool:
	return object.components == reference.components
