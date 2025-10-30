extends VBoxContainer
class_name AttributeEditor

static var BOOL_ATTRIBUTES: Array[Script] = [
	NoTouchAttribute,
]

static var FLAG_ATTRIBUTES: Dictionary[String, Array] = {
	"Hide": [HideSpriteAttribute, HideBaseAttribute, HideDetailAttribute, HideParticlesAttribute],
	"MusicScale": [MusicScaleSpriteAttribute, MusicScaleBaseAttribute, MusicScaleDetailAttribute, MusicScaleParticlesAttribute, MusicScaleHitboxAttribute]
}

var bool_properties: Dictionary[Script, BoolProperty]
var flag_properties: Dictionary[String, FlagsProperty]


func _init() -> void:
	BOOL_ATTRIBUTES.make_read_only()
	FLAG_ATTRIBUTES.make_read_only()


func _ready() -> void:
	for attribute in BOOL_ATTRIBUTES:
		var property := BoolProperty.new()
		property.name = attribute.get_global_name().trim_suffix("Attribute").capitalize()
		bool_properties[attribute] = property
		add_child(property)

	for category_name in FLAG_ATTRIBUTES:
		var property := FlagsProperty.new()
		property.name = category_name
		for attribute in FLAG_ATTRIBUTES[category_name]:
			property.flags.append(attribute.get_global_name().trim_prefix(category_name).trim_suffix("Attribute").capitalize())
		flag_properties[category_name] = property
		add_child(property)


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	var first_object: Node2D = selection.get(0)
	if not first_object:
		return
	connect_ui(selection)
	load_bool_properties(first_object)


func connect_ui(selection: Array[Node2D]) -> void:
	for attribute in bool_properties:
		var property: BoolProperty = bool_properties[attribute]
		var remove_connections := func(connection):
			if not "watcher" in connection.callable.get_method():
				property.value_changed.disconnect(connection.callable)
		property.value_changed.get_connections().map(remove_connections)
		property.value_changed.connect(save_bool_attribute.bind(attribute, selection))
	for category_name in flag_properties:
		var property: FlagsProperty = flag_properties[category_name]
		var remove_connections := func(connection):
			if not "watcher" in connection.callable.get_method():
				property.value_changed.disconnect(connection.callable)
		property.value_changed.get_connections().map(remove_connections)
		property.value_changed.connect(save_flag_attribute.bind(FLAG_ATTRIBUTES[category_name], selection))
		

func save_bool_attribute(enabled: bool, attribute_script: Script, selection: Array[Node2D]) -> void:
	for object in selection:
		if enabled:
			NodeUtils.get_node_or_add(
				object,
				str(attribute_script.get_global_name()),
				attribute_script,
				NodeUtils.SET_OWNER | NodeUtils.FORCE_READABLE_NAME
			)
		else:
			NodeUtils.get_children_of_type(object, attribute_script).map(NodeUtils.free_node)


func save_flag_attribute(flags: int, attribute_scripts: Array, selection: Array[Node2D]) -> void:
	for object in selection:
		for i in attribute_scripts.size():
			var attribute_script: Script = attribute_scripts[i]
			if flags & 1 << i:
				NodeUtils.get_node_or_add(
					object,
					str(attribute_script.get_global_name()),
					attribute_script,
					NodeUtils.SET_OWNER | NodeUtils.FORCE_READABLE_NAME
				)
			else:
				NodeUtils.get_children_of_type(object, attribute_script).map(NodeUtils.free_node)


func load_bool_properties(object: Node2D) -> void:
	for attribute in bool_properties:
		var property := bool_properties[attribute]
		property.set_value_no_signal(object.has_node(str(attribute.get_global_name())))
