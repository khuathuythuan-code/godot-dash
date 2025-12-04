extends Control
class_name InteractableEditor

# Scripts aren't constants but the array shouldn't be modified nontheless.
static var COMPONENT_BLACKLIST: Array[Script] = [
	JumpBoostComponent,
	GravityFlipChangerComponent,
	ReboundComponent,
	SpiderDashComponent,
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
	HideMarkersComponent,
]

# Querying this at runtime is overkill
static var MARKER_COMPONENTS: Array[Script] = [
	SingleUsageComponent,
	NoEffectsComponent,
]

static var are_arrays_initialized: bool

@export var components_root: Container
@export var separator: HSeparator
@export var markers_root: Container

var marker_properties: Dictionary[Script, BoolProperty]
var initial_values: Dictionary[Component, Variant]


func _init() -> void:
	if not are_arrays_initialized:
		COMPONENT_BLACKLIST.append_array(MARKER_COMPONENTS)
		COMPONENT_BLACKLIST.make_read_only()
		MARKER_COMPONENTS.make_read_only()
		are_arrays_initialized = true


func _ready() -> void:
	for marker in MARKER_COMPONENTS:
		var property := BoolProperty.new()
		property.name = marker.get_global_name().trim_suffix("Component").capitalize()
		marker_properties.set(marker, property)
		markers_root.add_child(property)


func _on_edit_handler_selection_changed(selection: Selection) -> void:
	clear_ui()
	if selection.is_empty() or not selection.all(is_interactable):
		return
	var interactables: Array[Interactable]
	interactables.assign(selection.to_array())
	build_ui(interactables)


func clear_ui() -> void:
	NodeUtils.free_children(components_root)


func rebuild_ui(interactables: Array[Interactable]) -> void:
	clear_ui()
	build_ui(interactables)


func build_ui(interactables: Array[Interactable]) -> void:
	var first_interactable: Interactable = interactables[0]
	var ui_root := VBoxContainer.new()
	var should_component_be_displayed := func(component):
		return (not component.get_script() in COMPONENT_BLACKLIST) and (not component.get_script() in MARKER_COMPONENTS)
	var displayed_components := first_interactable \
			.components \
			.filter(should_component_be_displayed)

	if displayed_components and same_ui(interactables):
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
				property = PropertyGenerator.from_property_list_field(field.type, field)
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
		if first_interactable.has(HideMarkersComponent):
			separator.hide()
			markers_root.hide()
		else:
			separator.visible = components_root.visible
			markers_root.show()
	else:
		components_root.hide()
		separator.hide()

	await get_tree().process_frame

	connect_ui(interactables, self)
	load_properties.call_deferred(first_interactable, self)


func connect_ui(interactables: Array[Interactable], ui_root: Control) -> void:
	var properties := NodeUtils.get_children_of_type(ui_root, Property, true)
	if properties.is_empty():
		return
	for property in properties as Array[Property]:
		var remove_connections := func(connection):
			if not "watcher" in connection.callable.get_method():
				property.value_changed.disconnect(connection.callable)
		property.value_changed.get_connections().map(remove_connections)
		NodeUtils.disconnect_all(property.interaction_ended)
		var property_name := property.name.to_snake_case()
		if property is BoolProperty and property in marker_properties.values():
			property.value_changed.connect(refresh_marker.bind(property, marker_properties.find_key(property), interactables))
			continue
		if property.has_meta(&"component_name"):
			var component_name: String = property.get_meta(&"component_name")
			for interactable: Interactable in interactables:
				var component: Component = interactable.get_node(component_name)
				if component not in initial_values:
					var _value: Variant = component.get(property_name)
					if _value is String:
						if component is TargetGroupComponent:
							_value = Constants.GROUP_PREFIX + _value
						elif component is TargetColorChannelComponent:
							_value = Constants.COLOR_CHANNEL_GROUP_PREFIX + _value
					initial_values[component] = _value
			property.value_changed.connect(save_property.bind(component_name, property_name, interactables))
			property.interaction_ended.connect(
				save_property_register.bind(
					component_name,
					property_name,
					interactables.map(Editor.version_history.to_nodepath)
				)
			)


func save_property(value: Variant, component_name: String, property_name: String, interactables: Array[Interactable]) -> void:
	for interactable: Interactable in interactables:
		var component: Component = interactable.get_node(component_name)
		var _value: Variant = value
		if _value is String:
			if component is TargetGroupComponent:
				_value = Constants.GROUP_PREFIX + value
			elif component is TargetColorChannelComponent:
				_value = Constants.COLOR_CHANNEL_GROUP_PREFIX + _value
		if component not in initial_values:
			initial_values[component] = _value
		component.set(property_name, _value)


func save_property_register(value: Variant, _previous: Variant, component_name: String, property_name: String, interactables: Array[Interactable]) -> void:
	var do_save_property := func(_interactables: Array[Interactable], new_value: Variant):
		for _interactable: Interactable in _interactables:
			var component: Component = _interactable.get_node(component_name)
			var _value: Variant = new_value
			if _value is String:
				if component is TargetGroupComponent:
					_value = Constants.GROUP_PREFIX + new_value
				elif component is TargetColorChannelComponent:
					_value = Constants.COLOR_CHANNEL_GROUP_PREFIX + _value
			component.set(property_name, _value)
			if component not in initial_values:
				initial_values[component] = _value
		load_properties(_interactables[0], self)
	var undo_save_property := func(_interactables_to_initial_values: Dictionary[Interactable, Variant]):
		for _interactable: Interactable in _interactables_to_initial_values:
			var component: Component = _interactable.get_node(component_name)
			var _value = _interactables_to_initial_values[_interactable]
			if _value is String:
				if component is TargetGroupComponent:
					_value = Constants.GROUP_PREFIX + _interactables_to_initial_values[_interactable]
				elif component is TargetColorChannelComponent:
					_value = Constants.COLOR_CHANNEL_GROUP_PREFIX + _value
			component.set(property_name, _value)
		load_properties(_interactables_to_initial_values.keys()[0], self)
	
	var interactables_snapshot: Array[Interactable] = interactables.duplicate()
	var map_interactable_to_initial_value := func(accum: Dictionary, interactable: Interactable):
		var component: Component = interactable.get_node(component_name)
		var initial_value: Variant = initial_values[component]
		initial_values.erase(component)
		if initial_value is Array:
			initial_value = initial_value.duplicate()
		accum[interactable] = initial_value
		return accum
	var interactables_to_initial_values: Dictionary[Interactable, Variant]
	interactables_to_initial_values.assign(interactables_snapshot.reduce(map_interactable_to_initial_value, {}))

	var version_history: VersionHistory = Editor.version_history
	version_history.create_action("Set '%s' on %s interactables" % [property_name, interactables_snapshot.size()])
	version_history.add_do_method(do_save_property.bind(interactables_snapshot, value))
	version_history.add_undo_method(undo_save_property.bind(interactables_to_initial_values))
	version_history.commit_action()


func refresh_marker(enabled: bool, property: BoolProperty, marker_script: Script, interactables: Array[Interactable]) -> void:
	var add_marker := func(_interactables: Array[Interactable]):
		for _interactable: Interactable in _interactables:
			var marker: Marker = NodeUtils.get_node_or_add(_interactable, str(marker_script.get_global_name()), marker_script, NodeUtils.SET_OWNER | NodeUtils.FORCE_READABLE_NAME)
			_interactable.register_public(marker)
		property.set_value_no_signal(true)
	var remove_marker := func(_interactables: Array[Interactable]):
		for _interactable: Interactable in _interactables:
			NodeUtils.get_children_of_type(_interactable, marker_script).map(func(marker):
				_interactable.components.erase(marker)
				marker.queue_free())
		property.set_value_no_signal(false)
	
	var interactables_snapshot: Array[Interactable] = interactables.duplicate()
	var version_history: VersionHistory = Editor.version_history
	version_history.create_action("Set '%s' to %s on %s interactables" % [marker_script.get_global_name(), enabled, interactables_snapshot.size()])
	version_history.add_do_method(add_marker.bind(interactables_snapshot) if enabled else remove_marker.bind(interactables_snapshot))
	version_history.add_undo_method(remove_marker.bind(interactables_snapshot) if enabled else add_marker.bind(interactables_snapshot))
	version_history.commit_action()


func load_properties(interactable: Interactable, ui_root: Control) -> void:
	var properties := NodeUtils.get_children_of_type(ui_root, Property, true)
	if properties.is_empty():
		return
	for property in properties as Array[Property]:
		if property is BoolProperty and property in marker_properties.values():
			property.set_value_no_signal(interactable.has(marker_properties.find_key(property)))
			continue
		var property_name := property.name.to_snake_case()
		if not property.has_meta(&"component_name"):
			continue
		var component := interactable.get_node(str(property.get_meta(&"component_name")))
		if component == null or component.get(property_name) == null:
			printerr("Can't load property ", property_name, " on ", interactable)
			continue
		var value = component.get(property_name)
		if value is String:
			if component is TargetGroupComponent:
				value = value.trim_prefix(Constants.GROUP_PREFIX)
			elif component is TargetColorChannelComponent:
				value = value.trim_prefix(Constants.COLOR_CHANNEL_GROUP_PREFIX)
		property.set_value_no_signal(value)


static func is_interactable(object: Node2D) -> bool:
	return object is Interactable


static func same_script(object: Interactable, reference: Interactable) -> bool:
	return object.get_script() == reference.get_script()


static func same_ui(interactables: Array[Interactable]) -> bool:
	if interactables.size() == 1:
		return true
	for interactable_idx in interactables.size():
		var object: Interactable = interactables[interactable_idx]
		var reference: Interactable = interactables[wrapi(interactable_idx + 1, 0, interactables.size())]
		if object.components.size() != reference.components.size():
			return false
		for component_idx in object.components.size():
			if object.components[component_idx].get_script() != reference.components[component_idx].get_script():
				return false
	return true
