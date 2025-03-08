class_name WalkingSDPCState
extends SDPCState

@onready var sprint_state: SprintingSDPCState = $"../Sprinting"
@onready var jump_state: JumpingSDPCState = $"../Jumping"
@onready var fall_state: FallingSDPCState = $"../Falling"
@onready var sneak_state: SneakingSDPCState = $"../Sneaking"
@onready var stand_state: StandingSDPCState = $"../Standing"


func enter() -> SDPCState:
	parent.is_standing = true
	parent.is_crouching = false
	parent.set_standing_collision()
	parent.wiggle_current_intensity = parent.WIGGLE_ON_WALKING_INTENSITY * parent.HEADBOBBLE
	return null


func process_physics(delta: float) -> SDPCState:
	parent.current_speed = lerp(parent.current_speed, parent.WALKING_SPEED, delta * parent.LERP_SPEED)
	parent.direction = lerp(parent.direction,
					(parent.body.global_transform.basis * Vector3(parent.input_dir.x, 0, parent.input_dir.y)).normalized(),
					delta * parent.LERP_SPEED
					)
	parent.wiggle_index += parent.WIGGLE_ON_WALKING_SPEED * delta
	parent.wiggle_vector.y = sin(parent.wiggle_index)
	parent.wiggle_vector.x = sin(parent.wiggle_index / 2) + 0.5

	parent.eyes.position.y = lerp(parent.eyes.position.y,
							parent.wiggle_vector.y * (parent.wiggle_current_intensity / 2.0),
							delta * parent.LERP_SPEED
													)
	parent.eyes.position.x = lerp(
							parent.eyes.position.x,
							parent.wiggle_vector.x * parent.wiggle_current_intensity,
							delta * parent.LERP_SPEED
													)


	if !parent.is_on_floor and !Input.is_action_just_pressed("jump"):
		return fall_state

	if parent.try_crouch or parent.crouch_raycast.is_colliding():
		return sneak_state

	if parent.direction.is_equal_approx(Vector3.ZERO):
		return stand_state


	return null


func process_handled_inputs(event: InputEvent) -> SDPCState:
	if event.is_action_pressed("jump") and parent.jump_timer.is_stopped():
		return jump_state

	if event.is_action_pressed("sprint"):
		return sprint_state
	return null
