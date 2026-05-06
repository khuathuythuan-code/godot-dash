class_name FireDashComponent
extends Component

# TODO figure out how to make cyan dash orbs work
## Dash orbs _completely_ override the player's velocity.

@export_flags("X", "Y") var snap: int = Constants.AxisBitflag.NONE
var path: Node
var initial_gameplay_rotation: float
var initial_horizontal_direction: int
var initial_speed: float


func _ready() -> void:
	$"../DashOrbPreview".visible = Editor.in_editor
	parent.interacted.connect(start)


func start(player: Player) -> void:
	if snap & Constants.AxisBitflag.X:
		LevelManager.player.global_position.x = get_parent().global_position.x
	if snap & Constants.AxisBitflag.Y:
		LevelManager.player.global_position.y = tan(get_parent().rotation) * (LevelManager.player.global_position.x - get_parent().global_position.x) + get_parent().global_position.y
	player.dash_control = self
	initial_gameplay_rotation = player.gameplay_rotation
	initial_speed = player.speed_multiplier
	if LevelManager.platformer:
		player.horizontal_direction = sign(cos(parent.global_rotation - initial_gameplay_rotation) * parent.scale.y)
	initial_horizontal_direction = player.horizontal_direction
	player.get_node("DashParticles").emitting = true
	player.get_node("DashFlame").show()
	if not parent.has(NoEffectsComponent):
		var dash_boom = player.DASH_BOOM.instantiate()
		dash_boom.position = player.to_local(parent.global_position)
		player.add_child(dash_boom)
