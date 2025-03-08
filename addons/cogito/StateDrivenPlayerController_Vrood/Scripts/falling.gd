class_name FallingSDPCState
extends SDPCState

@onready var jump_state: JumpingSDPCState = $"../Jumping"
@onready var land_state: LandingSDPCState = $"../Landing"
@onready var walk_state: WalkingSDPCState = $"../Walking"
@onready var sneak_state: SneakingSDPCState = $"../Sneaking"

var was_standing: bool

func enter() -> SDPCState:
	was_standing = parent.is_standing
	parent.is_in_air = true
	return null


func process_physics(delta: float) -> SDPCState:
	parent.direction = lerp(parent.direction,
				(parent.body.global_transform.basis * Vector3(parent.input_dir.x, 0, parent.input_dir.y)).normalized(),
				delta * parent.AIR_LERP_SPEED
			)
	if parent.is_on_floor():
		if parent.last_velocity.y < parent.landing_threshold:
			return land_state
		elif was_standing:
			return walk_state
		else:
			return sneak_state


	return null


func process_handled_inputs(event: InputEvent) -> SDPCState:

	if event.is_action_pressed("jump") and parent.jump_timer.is_stopped():
		if parent.multijump_enabled and parent.current_jumps < parent.max_jumps:
			return jump_state


	return null
