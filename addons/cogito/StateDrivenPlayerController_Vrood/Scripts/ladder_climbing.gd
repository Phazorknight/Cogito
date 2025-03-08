class_name LadderClimbingSDPCState
extends SDPCState

@onready var fall_state: FallingSDPCState = $"../Falling"
@onready var stand_state: StandingSDPCState = $"../Standing"
@onready var crouch_state: CrouchingSDPCState = $"../Crouching"


var jump = Input.is_action_pressed("jump")
var was_standing: bool


func enter() -> SDPCState:
	parent.on_ladder = true
	was_standing = parent.is_standing
	parent.is_standing = true
	parent.is_crouching = false
	parent.set_standing_collision()

	return null


func process_physics(delta: float) -> SDPCState:
	var CAN_SPRINT_ON_LADDER := parent.CAN_SPRINT_ON_LADDER
	var JUMP_VELOCITY := parent.JUMP_VELOCITY
	var LADDER_JUMP_SCALE := parent.LADDER_JUMP_SCALE
	var ladder_speed := parent.LADDER_SPEED
	# Applying ladder input_dir to direction
	var look_vector = parent.camera.get_camera_transform().basis
	var looking_down = look_vector.z.dot(Vector3.UP) > 0.5
	var y_dir = 1 if looking_down else -1
	parent.direction = (parent.body.global_transform.basis * Vector3(parent.input_dir.x,parent.input_dir.y * y_dir,0)).normalized()

		#Step off ladder when on ground
	if parent.is_on_floor() and not parent.ladder_on_cooldown:
		parent.on_ladder = false
		if was_standing:
			return stand_state
		elif !was_standing:
			return crouch_state

	if CAN_SPRINT_ON_LADDER and Input.is_action_pressed("sprint") and parent.input_dir.length_squared() > 0.1:
		parent.is_sprinting = true
		if parent.stamina_attribute.value_current > 0:
			ladder_speed = parent.LADDER_SPRINT_SPEED
	else:
		parent.is_sprinting = false

	if jump:
		 # We return to the fall state instead of the jump state because we are handling jump here
		parent.main_velocity += parent.look_vector * Vector3(JUMP_VELOCITY * LADDER_JUMP_SCALE,
													JUMP_VELOCITY * LADDER_JUMP_SCALE,
													JUMP_VELOCITY * LADDER_JUMP_SCALE)
		return fall_state


	parent.current_speed = ladder_speed
	return null
