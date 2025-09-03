extends Component
class_name HiddenOutsideEditorComponent


func _ready() -> void:
	super()
	parent.visible = LevelManager.in_editor
