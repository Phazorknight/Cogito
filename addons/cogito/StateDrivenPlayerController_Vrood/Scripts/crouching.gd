class_name CrouchingSDPCState
extends SDPCState

@onready var fall_state: FallingSDPCState = $"../Falling"
@onready var stand_state: StandingSDPCState = $"../Standing"
@onready var sneak_state: SneakingSDPCState = $"../Sneaking"
@onready var free_look_state: FreeLookingSDPCState = $"../FreeLooking"
@onready var jump_state: JumpingSDPCState = $"../Jumping"


func enter() -> SDPCState:
	parent.is_idle = true
	parent.is_crouching = true
	parent.is_standing = false
	parent.set_crouching_collision()
	parent.main_velocity = Vector3.ZERO
	parent.current_speed = 0.0
	return null


func process_physics(delta: float) -> SDPCState:
	if !parent.is_on_floor() and !Input.is_action_just_pressed("jump"):
		parent.is_idle = false
		return fall_state

	if !parent.crouch_raycast.is_colliding() and !parent.crouch_input():
		parent.is_crouching = false
		return stand_state

	if parent.direction != Vector3.ZERO:
		parent.is_idle = false
		return sneak_state

	return null


func process_handled_inputs(event: InputEvent) -> SDPCState:
	if event.is_action_pressed("sprint"):
		parent.is_crouching = false
		return stand_state

	if event.is_action_pressed("jump") and parent.CAN_CROUCH_JUMP:
		return jump_state

	if event.is_action_pressed("free_look"):
		return free_look_state

	return null
