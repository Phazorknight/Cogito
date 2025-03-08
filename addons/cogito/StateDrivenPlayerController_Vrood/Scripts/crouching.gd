class_name CrouchingSDPCState
extends SDPCState


@export var sneak_state: SneakingSDPCState
@export var stand_state: StandingSDPCState
@export var fall_state: FallingSDPCState

func enter() -> SDPCState:
	parent.is_crouching = true
	parent.is_idle = true
	parent.set_crouching_collision()
	return null


func exit() -> SDPCState:
	return null


func process_physics(delta: float) -> SDPCState:
	if !parent.is_on_floor():
		return fall_state

	if !parent.try_crouch:
		parent.is_crouching = false
		return stand_state

	if parent.direction != Vector3.ZERO:
		return sneak_state


	return null


func process_frames(delta: float) -> SDPCState:
	return null

func process_handled_inputs(event: InputEvent) -> SDPCState:
	return null

func process_unhanled_inputs(event: InputEvent) -> SDPCState:
	return null
