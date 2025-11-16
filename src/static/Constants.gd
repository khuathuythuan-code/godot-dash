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
