extends Component
class_name HiddenOutsideEditorComponent


func _ready() -> void:
	super()
	parent.visible = Editor.in_editor
