extends VBoxContainer
class_name AttributeEditor

var BOOL_ATTRIBUTES: Array[Script] = [
	NoTouchAttribute,
]

var CONTAINER_ATTRIBUTES: Dictionary[String, Array] = {
	"HideAttribute": [HideSpriteAttribute, HideBaseAttribute, HideDetailAttribute, HideParticlesAttribute],
}

var properties: Dictionary[Script, BoolProperty]

var dictionary_properties: Dictionary[Script, Dictionary]


func _init() -> void:
	BOOL_ATTRIBUTES.make_read_only()
	CONTAINER_ATTRIBUTES.make_read_only()

 # I know this kind of sucks but it's only getting run once so it's fine right???
func _ready() -> void:
	for attribute in BOOL_ATTRIBUTES:
		var property := BoolProperty.new()
		property.name = attribute.get_global_name().trim_suffix("Attribute").capitalize()
		properties.set(attribute, property)
		add_child(property)

	for attribute in CONTAINER_ATTRIBUTES:
		var paramater_box := FoldableContainer.new()
		paramater_box.name = attribute.trim_suffix("Attribute").capitalize()
		paramater_box.title = paramater_box.name
		paramater_box.folded = true
		add_child(paramater_box)
		paramater_box.add_child(VBoxContainer.new())
		for paramater in CONTAINER_ATTRIBUTES.get(attribute):
			var paramater_property = BoolProperty.new()
			paramater_property.name = paramater.get_global_name().trim_suffix("Attribute").capitalize()
			properties.set(paramater, paramater_property)
			paramater_box.get_child(0).add_child(paramater_property)


func _on_edit_handler_selection_changed(selection: Array[Node2D]) -> void:
	if selection.is_empty():
		return
	var first_object: Node2D = selection.get(0)
	if not first_object:
		return
	connect_ui(selection)
	load_properties(first_object)


func connect_ui(selection: Array[Node2D]) -> void:
	for attribute in properties:
		var property := properties[attribute]
		var remove_connections := func(connection):
			if not "watcher" in connection.callable.get_method():
				property.value_changed.disconnect(connection.callable)
		property.value_changed.get_connections().map(remove_connections)
		property.value_changed.connect(save_attribute.bind(attribute, selection))
		

func save_attribute(enabled: bool, attribute: Script, selection: Array[Node2D]) -> void:
	for object in selection:
		if enabled:
			NodeUtils.get_node_or_add(object, str(attribute.get_global_name()), attribute, NodeUtils.SET_OWNER | NodeUtils.FORCE_READABLE_NAME)
		else:
			NodeUtils.get_children_of_type(object, attribute).map(func(attribute_instance): attribute_instance.queue_free())


func load_properties(object: Node2D) -> void:
	for attribute in properties:
		var property := properties[attribute]
		property.set_value_no_signal(object.has_node(str(attribute.get_global_name())))
