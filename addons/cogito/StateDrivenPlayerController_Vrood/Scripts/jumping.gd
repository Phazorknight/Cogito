class_name JumpingSDPCState
extends SDPCState

var was_standing: bool
var jump_vel: float

@onready var fall_state: FallingSDPCState = $"../Falling"


func enter() -> SDPCState:
	# Checks if we can jump based on timer
	if !parent.jump_timer.is_stopped():
		return prior_state
	else:
		parent.jump_timer.start()
	# Checks if we can jump based on Multijump counts
	if parent.multijump_enabled:
		if parent.current_jumps < parent.max_jumps:
			parent.current_jumps += 1
		else:
			return prior_state

	var doesnt_need_stamina = not parent.stamina_attribute or parent.stamina_attribute.value_current >= parent.stamina_attribute.jump_exhaustion
	if doesnt_need_stamina:
		if parent.stamina_attribute:
			parent.decrease_attribute("stamina", parent.stamina_attribute.jump_exhaustion)

		was_standing = parent.is_standing
		parent.is_jumping = true

		if was_standing:
			jump_vel = parent.JUMP_VELOCITY
		elif !was_standing:
			jump_vel = parent.CROUCH_JUMP_VELOCITY

			parent.animationPlayer.play("jump")
			Audio.play_sound(parent.jump_sound)
			parent.main_velocity.y = jump_vel

	elif not doesnt_need_stamina:
		CogitoGlobals.debug_log(parent.is_logging, "state_driven_player_controller", "Not enough Stamina to Jump")
		return prior_state
	return null


func exit() -> SDPCState:
	parent.is_jumping = false
	return null


func process_physics(delta: float) -> SDPCState:
	parent.direction = lerp(parent.direction,
				(parent.body.global_transform.basis * Vector3(parent.input_dir.x, 0, parent.input_dir.y)).normalized(),
				delta * parent.AIR_LERP_SPEED
			)
	if parent.last_velocity.y < 0.0:
		return fall_state
	return null


func process_handled_inputs(event: InputEvent) -> SDPCState:
	# By holding jump, we slightly delay the fall state, but if we release early we can do a shallower jump
	if event.is_action_released("jump"):
		return fall_state

	return null
