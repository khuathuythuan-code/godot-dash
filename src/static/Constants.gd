@abstract
class_name Constants

enum Axis {
	BOTH,
	X,
	Y,
}

enum AxisBitflag {
	NONE = 0,
	X = 1 << 0,
	Y = 1 << 1,
}

enum SpecialColorChannel {
	BACKGROUND,
	GROUND,
	LINE,
	# TODO implement players colors
	P1,
	P2,
	GLOW,
}

const GROUP_PREFIX: String = "g_"
const COLOR_CHANNEL_GROUP_PREFIX := "c_"

const DEFAULT_PLAYER_POSITION: Vector2 = Vector2(640.0, 861.0)
const DEFAULT_BACKGROUND_COLOR: Color = Color("#3670ff")
const DEFAULT_GROUND_COLOR: Color = Color("#1b4bc4")
const DEFAULT_LINE_COLOR: Color = Color.WHITE

const CELL_SIZE: int = 128
const CELLS_TO_PX := Vector2(CELL_SIZE, -CELL_SIZE)

#const LEVEL_DIR: String = "user://created_levels/levels/"
const LEVEL_DIR: String = "res://src/testlevels/"
const SONG_DIR: String = "user://created_levels/songs/"
const FONT_DIR: String = "user://created_levels/fonts/"
const ICON_DIR: String = "res://assets/textures/player/"
const CUSTOM_ICON_DIR: String = "user://textures/player/"
const REPLAYS_DIR: String = "user://replays/"

const LAYER_META: StringName = &"layer"
const TEXTURE_OVERRIDE_META: StringName = &"texture_override"

const FREED: String = "__freed"
