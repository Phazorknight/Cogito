class_name SneakingSDPCState
extends SDPCState


@onready var walk_state: WalkingSDPCState = $"../Walking"
@onready var sprint_state: SprintingSDPCState = $"../Sprinting"
@onready var fall_state: FallingSDPCState = $"../Falling"
@onready var crouch_state: CrouchingSDPCState = $"../Crouching"
@onready var jump_state: JumpingSDPCState = $"../Jumping"


func enter() -> SDPCState:
	parent.is_idle = false
	parent.is_crouching = true
	parent.set_crouching_collision()
	parent.wiggle_current_intensity = parent.WIGGLE_ON_CROUCHING_INTENSITY
	return null


func exit() -> SDPCState:
	return null


func process_physics(delta: float) -> SDPCState:
	parent.direction = lerp(parent.direction,
					(parent.body.global_transform.basis * Vector3(parent.input_dir.x, 0, parent.input_dir.y)).normalized(),
					delta * parent.LERP_SPEED
					)
	parent.current_speed = lerp(parent.current_speed, parent.CROUCHING_SPEED, delta * parent.LERP_SPEED)
	parent.wiggle_index += parent.WIGGLE_ON_CROUCHING_SPEED * delta
	if !parent.is_on_floor():
		return fall_state

	if parent.direction.is_equal_approx(Vector3.ZERO):
		return crouch_state

	if !parent.crouch_input():
		parent.is_crouching = false
		parent.is_standing = true
		parent.set_standing_collision()
		return walk_state


	return null


func process_frames(delta: float) -> SDPCState:
	return null

func process_handled_inputs(event: InputEvent) -> SDPCState:
	if event.is_action_pressed("sprint"):
		parent.is_standing = true
		parent.is_crouching = false
		parent.set_standing_collision()
		return walk_state

	if event.is_action_pressed("jump"):
		return jump_state

	return null

func process_unhandled_inputs(event: InputEvent) -> SDPCState:
	return null
