class_name SprintingSDPCState
extends SDPCState

@onready var walk_state: WalkingSDPCState = $"../Walking"
@onready var jump_state: JumpingSDPCState = $"../Jumping"
@onready var slide_state: SlidingSDPCState = $"../Sliding"
@onready var fall_state: FallingSDPCState = $"../Falling"


func enter() -> SDPCState:
	parent.is_standing = true
	parent.is_crouching = false
	parent.set_standing_collision()
	parent.wiggle_current_intensity = parent.WIGGLE_ON_SPRINTING_INTENSITY * parent.HEADBOBBLE
	return null


func process_physics(delta: float) -> SDPCState:
	if parent.stamina_attribute and parent.stamina_attribute.value_current <= 0:
		return walk_state

	if parent.direction.is_equal_approx(Vector3.ZERO):
		return walk_state

	if parent.crouch_input() and parent.slide_enabled:
		return slide_state

	parent.direction = lerp(parent.direction,
					(parent.body.global_transform.basis * Vector3(parent.input_dir.x, 0, parent.input_dir.y)).normalized(),
					delta * parent.LERP_SPEED
					)
	parent.current_speed = lerp(parent.current_speed, parent.SPRINTING_SPEED, parent.LERP_SPEED * delta)

	parent.wiggle_index += parent.WIGGLE_ON_SPRINTING_SPEED * delta
	parent.wiggle_vector.y = sin(parent.wiggle_index)
	parent.wiggle_vector.x = sin(parent.wiggle_index / 2) + 0.5
	parent.eyes.position.y = lerp(
			parent.eyes.position.y,
			parent.wiggle_vector.y * (parent.wiggle_current_intensity / 2.0),
			delta * parent.LERP_SPEED
		)
	parent.eyes.position.x = lerp(
			parent.eyes.position.x,
			parent.wiggle_vector.x * parent.wiggle_current_intensity,
			delta * parent.LERP_SPEED
		)

	return null


func process_inputs(event) -> SDPCState:
	if event.is_action_pressed("jump"):
		return jump_state
	return null
