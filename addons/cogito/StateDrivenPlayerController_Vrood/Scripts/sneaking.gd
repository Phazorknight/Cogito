class_name SneakingSDPCState
extends SDPCState

@export var walk_state: WalkingSDPCState
@export var sprint_state: SprintingSDPCState
@export var crouch_state: CrouchingSDPCState
@export var fall_state: FallingSDPCState
@export var jump_state: JumpingSDPCState


func enter() -> SDPCState:
	parent.is_idle = false
	parent.is_crouching = true
	return null


func exit() -> SDPCState:
	return null


func process_physics(delta: float) -> SDPCState:
	if !parent.is_on_floor():
		return fall_state

	if parent.direction.is_equal_approx(Vector3.ZERO):
		return crouch_state

	if !parent.try_crouch:
		parent.is_crouching = false
		parent.call_deferred("set_standing_collision")
		return walk_state


	return null


func process_frames(delta: float) -> SDPCState:
	return null

func process_handled_inputs(event: InputEvent) -> SDPCState:
	if event.is_action_pressed("sprint"):
		parent.is_crouching = false
		parent.call_deferred("set_standing_collision")
		return walk_state

	if event.is_action_pressed("jump"):
		return jump_state

	return null

func process_unhanled_inputs(event: InputEvent) -> SDPCState:
	return null
