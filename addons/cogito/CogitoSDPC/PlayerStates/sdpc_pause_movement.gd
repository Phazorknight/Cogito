class_name SDPCStatePauseMovement
extends SDPCState

#NOTE: Use Case: Vendors, Pause Menus, UI
var was_moving: bool

func enter():
	super()
	# Hold reference to player movement flag
	was_moving = player.is_moving
	player.is_moving = false
	player.is_paused = true
	if InputHelper.device_index == -1:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func exit():
	# Reset flag as appropriate
	player.is_moving = was_moving
	player.is_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
