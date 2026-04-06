@icon("res://assets/textures/icons/node_icons/layers.svg")
class_name Layer
extends Node2D
## Marker class to identify layers in the level.

var hidden_in_editor: bool = false:
	set(value):
		hidden_in_editor = value
		modulate.a = 1.0 if not value else Config.hidden_layers_alpha
var locked: bool = false
