class_name PausedSDPCState
extends SDPCState

var before_pause_velocity: Vector3

func enter() -> SDPCState:
	parent.is_movement_paused = true
	if InputHelper.device_index == -1:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	return null


func exit() -> SDPCState:
	parent.is_movement_paused = false

	parent._reload_options()
	parent._on_resume_movement()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("exit pause state")
	return null
