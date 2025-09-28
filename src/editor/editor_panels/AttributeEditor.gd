extends VBoxContainer
class_name AttributeEditor

var ATTRIBUTES: Array[Script] = [
	NoTouchAttribute
]

var properties: Dictionary[Script, BoolProperty]


func _init() -> void:
	ATTRIBUTES.make_read_only()


func _ready() -> void:
	for attribute in ATTRIBUTES:
		var property := BoolProperty.new()
		property.name = attribute.get_global_name().trim_suffix("Attribute").capitalize()
		properties.set(attribute, property)
		add_child(property)


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
