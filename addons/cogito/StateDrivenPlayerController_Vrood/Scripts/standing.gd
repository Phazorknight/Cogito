class_name StandingSDPCState
extends SDPCState

## Player's default idle state


## Transition States

@export var jump_state: JumpingSDPCState
@export var fall_state: FallingSDPCState
@export var walk_state: WalkingSDPCState
@export var crouch_state: CrouchingSDPCState
@export var free_look_state: FreeLookingSDPCState



func enter() -> SDPCState:
	parent.set_standing_collision()
	parent.reset_state_flags()
	parent.main_velocity = Vector3.ZERO
	return null


func exit() -> SDPCState:
	parent.is_standing = false
	return null


func process_physics(delta: float) -> SDPCState:
	if parent.direction != Vector3.ZERO:
		parent.is_idle = false
		return walk_state

	if !parent.is_on_floor() and !Input.is_action_just_pressed("jump"):
		parent.is_idle = false
		return fall_state

	return null



func process_handled_inputs(event: InputEvent) -> SDPCState:
	if event.is_action_pressed("free_look"):
		return free_look_state

	if event.is_action_pressed("jump") and parent.jump_timer.is_stopped():
		parent.is_idle = false
		return jump_state

	if parent.try_crouch:
		return crouch_state

	return null


#func process_frames(delta: float) -> SDPCState:
	#return null
#func process_unhanled_inputs(event: InputEvent) -> SDPCState:
	#return null
