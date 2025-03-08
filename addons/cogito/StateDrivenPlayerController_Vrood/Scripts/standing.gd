class_name StandingSDPCState
extends SDPCState

## Player's default idle state

## Transition States
@onready var jump_state: JumpingSDPCState = $"../Jumping"
@onready var walk_state: WalkingSDPCState = $"../Walking"
@onready var fall_state: FallingSDPCState = $"../Falling"
@onready var free_look_state: FreeLookingSDPCState = $"../FreeLooking"
@onready var crouch_state: CrouchingSDPCState = $"../Crouching"


func enter() -> SDPCState:
	parent.reset_state_flags_to_idle()
	parent.is_idle = true
	parent.is_standing = true
	parent.is_crouching = false
	parent.set_standing_collision()
	parent.main_velocity = Vector3.ZERO
	parent.current_speed = 0.0
	return null


func process_physics(delta: float) -> SDPCState:
	if !parent.direction.is_equal_approx(Vector3.ZERO):
		parent.is_idle = false
		return walk_state

	if !parent.is_on_floor() and !Input.is_action_just_pressed("jump"):
		parent.is_idle = false
		return fall_state

	if parent.crouch_input() or parent.crouch_raycast.is_colliding():
		return crouch_state

	return null


func process_handled_inputs(event: InputEvent) -> SDPCState:
	if event.is_action_pressed("free_look"):
		return free_look_state

	if event.is_action_pressed("jump") and parent.jump_timer.is_stopped():
		parent.is_idle = false
		return jump_state

	return null

# Here are the other built in functions for States.
#func process_frames(delta: float) -> SDPCState:
	#return null

#func process_unhandled_inputs(event: InputEvent) -> SDPCState:
	#return null
