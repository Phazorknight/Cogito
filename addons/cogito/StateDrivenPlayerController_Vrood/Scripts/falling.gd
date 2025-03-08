class_name FallingSDPCState
extends SDPCState

@export var land_state: LandingSDPCState
@export var jump_state: JumpingSDPCState

func enter() -> SDPCState:
	parent.is_in_air = true
	return null


func exit() -> SDPCState:
	parent.is_in_air = false
	return null


func process_physics(delta: float) -> SDPCState:
	if parent.is_on_floor():
		return land_state
	return null


func process_frames(delta: float) -> SDPCState:
	return null

func process_handled_inputs(event: InputEvent) -> SDPCState:

	if event.is_action_just_pressed("jump") and prior_state is not JumpingSDPCState:
		if parent.multijumps >= parent.current_jumps:
			parent.current_jumps += 1
			return jump_state
	return null

func process_unhanled_inputs(event: InputEvent) -> SDPCState:
	return null
