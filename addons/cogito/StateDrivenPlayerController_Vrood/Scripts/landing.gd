class_name LandingSDPCState
extends SDPCState

@onready var stand_state: StandingSDPCState = $"../Standing"
@onready var crouch_state: CrouchingSDPCState = $"../Crouching"

var was_standing: bool

func enter() -> SDPCState:
	was_standing = parent.is_standing

	var velocity_ratio: float = clamp((parent.last_velocity.y - parent.min_landing_velocity) / (parent.max_landing_velocity - parent.min_landing_velocity), 0.0, 1.0)
	parent.LandingVolume = lerp(parent.min_volume_db, parent.max_volume_db, velocity_ratio)
	parent.LandingPitch = lerp(parent.max_pitch, parent.min_pitch, velocity_ratio)

	parent.footstep_player._play_interaction("landing")
	if parent.fall_damage > 0 and parent.last_velocity.y <= parent.fall_damage_threshold:
		parent.decrease_attribute("health", parent.fall_damage)
	return null


func exit() -> SDPCState:

	return null


func process_physics(delta: float) -> SDPCState:
	if !parent.is_movement_paused or !parent.is_showing_ui:
		#CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "668 Standing up...")
		parent.eyes.position.y = lerp(parent.eyes.position.y, 0.0, delta * parent.LERP_SPEED)
		parent.eyes.position.x = lerp(parent.eyes.position.x, 0.0, delta * parent.LERP_SPEED)

		if parent.last_velocity.y <= -7.5:
			parent.head.position.y = lerp(parent.head.position.y,
											 parent.CROUCHING_DEPTH,
											 delta * parent.LERP_SPEED)
			parent.set_crouching_collision()
			if !parent.disable_roll_anim:
				parent.animationPlayer.play("roll")
				if parent.stand_after_roll:
					CogitoGlobals.debug_log(parent.is_logging, "cogito_player.gd", "523: Standing after roll.")
					parent.head.position.y = lerp(parent.head.position.y, 0.0, delta * parent.LERP_SPEED)
					return stand_state


		elif parent.last_velocity.y <= -5.0:
			parent.animationPlayer.play("landing")


	if !was_standing:
		return crouch_state
	else:
		return stand_state
	return null


func process_frames(delta: float) -> SDPCState:
	return null

func process_handled_inputs(event: InputEvent) -> SDPCState:
	return null

func process_unhandled_inputs(event: InputEvent) -> SDPCState:
	return null
