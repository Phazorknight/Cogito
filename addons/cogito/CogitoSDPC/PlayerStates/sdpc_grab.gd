class_name SDPCStateGrab
extends SDPCState

# State that the chracacter is hanging from a ledge
@export_group("State Connections")
@export var clamber_state: SDPCStateClamber # climb over
@export var fall_state: SDPCStateFall # release ledge
@export var jump_state: SDPCStateJump # jump from wall

func enter():
	player.is_grabbing = true
	player.is_moving = false


func exit():
	player.is_grabbing = false
