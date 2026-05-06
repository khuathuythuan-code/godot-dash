class_name PhantomCameraHistory
extends Node

enum Status {
	INACTIVE,
	PREVIOUS_ACTIVE,
	CURRENT_ACTIVE,
}

var _history: Array[PhantomCamera2D]


func change_phantomcamera(current_phantomcamera: PhantomCamera2D, new_phantomcamera: PhantomCamera2D):
	if len(_history) >= 1:
		_history[-1].set_priority(Status.INACTIVE)
	current_phantomcamera.set_priority(Status.PREVIOUS_ACTIVE)
	_history.push_back(current_phantomcamera)
	new_phantomcamera.set_priority(Status.CURRENT_ACTIVE)


func previous_phantomcamera(current_phantomcamera: PhantomCamera2D):
	var previous_camera: PhantomCamera2D = _history.pop_back()
	if not previous_camera:
		return
	current_phantomcamera.set_priority(Status.INACTIVE)
	previous_camera.set_priority(Status.CURRENT_ACTIVE)
