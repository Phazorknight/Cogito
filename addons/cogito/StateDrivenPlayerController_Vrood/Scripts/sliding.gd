class_name SlidingSDPCState
extends SDPCState

@onready var walk_state: WalkingSDPCState = $"../Walking"
@onready var sneak_state: SneakingSDPCState = $"../Sneaking"
@onready var hop_state: HoppingSDPCState = $"../Hopping"
@onready var fall_state: FallingSDPCState = $"../Falling"


func enter() -> SDPCState:
	parent.is_crouching = true
	parent.is_standing = false
	parent.is_sliding = true
	parent.is_free_looking = true
	parent.set_crouching_collision()
	if parent.sliding_timer.is_stopped():
		parent.sliding_timer.start()
	parent.slide_vector = parent.input_dir
	parent.wiggle_current_intensity = parent.WIGGLE_ON_CROUCHING_INTENSITY
	return null


func exit() -> SDPCState:
	parent.is_sliding = false
	return null


func process_physics(delta: float) -> SDPCState:
	parent.wiggle_index += parent.WIGGLE_ON_CROUCHING_SPEED * delta
	parent.eyes.rotation.z = lerp(parent.eyes.rotation.z, deg_to_rad(4.0), delta * parent.LERP_SPEED)


	if Input.is_action_pressed("sprint"):
		parent.is_free_looking = false
		parent.set_standing_collision()
		parent.body.rotation.y += parent.neck.rotation.y
		parent.neck.rotation.y = 0
		parent.eyes.rotation.z = lerp(
			parent.eyes.rotation.z,
			0.0,
			delta * parent.LERP_SPEED)
		parent.sliding_timer.stop()
		return walk_state


		parent.direction = (parent.body.global_transform.basis * Vector3(parent.slide_vector.x, 0.0, parent.slide_vector.y)).normalized()
		parent.current_speed = (parent.sliding_timer.time_left / parent.sliding_timer.wait_time + 0.5) * parent.SLIDING_SPEED

	return null


func process_frames(delta: float) -> SDPCState:
	if parent.sliding_timer.is_stopped():
		parent.is_free_looking = false
		parent.body.rotation.y += parent.neck.rotation.y
		parent.neck.rotation.y = 0
		parent.eyes.rotation.z = lerp(
			parent.eyes.rotation.z,
			0.0,
			delta * parent.LERP_SPEED)
		return sneak_state

	elif !parent.is_on_floor():
		parent.is_free_looking = false
		parent.body.rotation.y += parent.neck.rotation.y
		parent.neck.rotation.y = 0
		parent.eyes.rotation.z = lerp(
			parent.eyes.rotation.z,
			0.0,
			delta * parent.LERP_SPEED)
		parent.sliding_timer.stop()
		return fall_state

	return null

func process_handled_inputs(event: InputEvent) -> SDPCState:
	if event.is_action_pressed("jump") and parent.jump_timer.is_stopped():
	# Checks if we can jump based on Multijump counts
		if parent.multijump_enabled and parent.current_jumps < parent.max_jumps:
				parent.current_jumps += 1
				return hop_state

	return null
