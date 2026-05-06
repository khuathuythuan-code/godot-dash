class_name PhantomCameraTween
extends Resource

const PcamConstants = preload("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_constants.gd")

## The time it takes to tween to this property
@export var duration: float = 1

## The transition bezier type for the tween
@export var transition: PcamConstants.TweenTransitions = PcamConstants.TweenTransitions.LINEAR

## The ease type for the tween
@export var ease: PcamConstants.TweenEases = PcamConstants.TweenEases.EASE_IN_OUT
