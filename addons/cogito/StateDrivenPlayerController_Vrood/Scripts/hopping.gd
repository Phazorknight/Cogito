class_name HoppingSDPCState
extends SDPCState

@onready var slide_state: SlidingSDPCState = $"../Sliding"
@onready var sneak_state: SneakingSDPCState = $"../Sneaking"

var time_to_begin_falling: float = 1.0
var jump_vel: float

func enter() -> SDPCState:
	parent.jump_timer.start()

	var doesnt_need_stamina = not parent.stamina_attribute or parent.stamina_attribute.value_current >= parent.stamina_attribute.jump_exhaustion
	if doesnt_need_stamina:
		if parent.stamina_attribute:
			parent.decrease_attribute("stamina", parent.stamina_attribute.jump_exhaustion)

		jump_vel = parent.JUMP_VELOCITY * parent.SLIDE_JUMP_MOD

		parent.animationPlayer.play("jump")
		Audio.play_sound(parent.jump_sound)
		parent.main_velocity.y = jump_vel
		if parent.CAN_BUNNYHOP:
			parent.main_velocity.x *= parent.BUNNY_HOP_ACCELERATION
			parent.main_velocity.z *= parent.BUNNY_HOP_ACCELERATION

		parent.is_jumping = true
		parent.is_in_air = true
		parent.jumped_from_slide = true


	elif not doesnt_need_stamina:
		CogitoGlobals.debug_log(parent.is_logging, "state_driven_player_controller", "Not enough Stamina to Jump")
		return prior_state

	return null


func exit() -> SDPCState:
	parent.jumped_from_slide = false
	parent.is_jumping = false
	parent.is_in_air = false
	return null


func process_physics(delta: float) -> SDPCState:
	parent.direction = lerp(parent.direction,
				(parent.body.global_transform.basis * Vector3(parent.input_dir.x, 0, parent.input_dir.y)).normalized(),
				delta * parent.AIR_LERP_SPEED
			)
	parent.eyes.rotation.z = lerp(parent.eyes.rotation.z, deg_to_rad(4.0), delta * parent.LERP_SPEED)

	if parent.is_on_floor():
		if parent.sliding_timer.is_stopped():
			parent.is_free_looking = false
			parent.body.rotation.y += parent.neck.rotation.y
			parent.neck.rotation.y = 0
			parent.eyes.rotation.z = lerp(parent.eyes.rotation.z, 0.0, delta * parent.LERP_SPEED)
			return sneak_state

		if Input.is_action_pressed("jump") and parent.jump_timer.is_stopped():
				# Checks if we can jump based on Multijump counts
			if parent.multijump_enabled and parent.current_jumps < parent.max_jumps:
				parent.current_jumps += 1
				return self

		else:
			return slide_state

	# When falling, give a slight delay before we timeout bunny hopping
	elif !parent.is_on_floor():
		parent.direction = (parent.body.global_transform.basis * Vector3(parent.slide_vector.x, 0.0, parent.slide_vector.y)).normalized()
		parent.current_speed = (parent.sliding_timer.time_left / parent.sliding_timer.wait_time + 0.5) * parent.SLIDING_SPEED

		await get_tree().create_timer(time_to_begin_falling).timeout
		parent.is_free_looking = false
		parent.jumped_from_slide = false

		parent.body.rotation.y += parent.neck.rotation.y
		parent.neck.rotation.y = 0
		parent.eyes.rotation.z = lerp(parent.eyes.rotation.z, 0.0, delta * parent.LERP_SPEED)
		return sneak_state # return to sneak state to let it handle Collision & give us a safer "prior state"


	return null
