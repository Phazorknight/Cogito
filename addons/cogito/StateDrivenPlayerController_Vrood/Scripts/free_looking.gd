class_name FreeLookingSDPCState
extends SDPCState

# NOTE: This is now a distinct state from Sliding
@onready var crouch_state: CrouchingSDPCState = $"../Crouching"
@onready var stand_state: StandingSDPCState = $"../Standing"

var was_standing: bool

func enter() -> SDPCState:
	parent.is_free_looking = true
	parent.is_idle = true
	was_standing = parent.is_standing
	return null

func exit() -> SDPCState:
	parent.is_free_looking = false
	return null


func process_physics(delta: float) -> SDPCState:
	if parent.input_dir:
		parent.input_dir = Vector2.ZERO
	if parent.main_velocity:
		parent.main_velocity = Vector3.ZERO
	parent.eyes.rotation.z = -deg_to_rad(parent.neck.rotation.y * parent.FREE_LOOK_TILT_AMOUNT)

	if !Input.is_action_pressed("free_look"):
		parent.body.rotation.y += parent.neck.rotation.y
		parent.neck.rotation.y = 0.0
		parent.eyes.rotation.z = lerp(parent.eyes.rotation.z, 0.0, delta * parent.LERP_SPEED)
		if was_standing:
			return stand_state
		else:
			return crouch_state

	return null
