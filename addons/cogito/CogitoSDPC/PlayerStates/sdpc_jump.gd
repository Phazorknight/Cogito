class_name SDPCStateJump
extends SDPCState

@export_group("State Connections")
@export var fall_state: SDPCStateFall
@export var grab_state: SDPCStateGrab
@export var idle_state: SDPCStateIdle
@export var move_state: SDPCStateMove

@export_group("State Properties")
@export var jump_exhaustion: float

var stamina_attribute_reference: CogitoStaminaAttribute

func enter() -> void:
	super()


	# Set Stamina Attribute reference if it wasn't set before
	if !stamina_attribute_reference:
		stamina_attribute_reference = player.player_attributes.get("stamina")

	# Check if enough stamina
	if jump_exhaustion > 0:
		if stamina_attribute_reference.value_current >= jump_exhaustion:
			stamina_attribute_reference.subtract(jump_exhaustion)

			move_speed = player.walk_back_speed
			player.velocity.y = sqrt(player.jump_height * 2 * player.gravity)

			print("stamina= ", stamina_attribute_reference.value_current)
		else:
			move_speed = player.walk_back_speed
			return

	else:
		move_speed = player.walk_back_speed
		player.velocity.y = sqrt(player.jump_height * 2 * player.gravity)


func process_physics(delta: float) -> SDPCState:
	if player.velocity.y < 0:
		return fall_state

	var input_dir = player.input_direction
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# If the floor magically appears under our character while they are ascending
	if player.is_on_floor():
		if input_dir:
			return move_state
		else:
			return idle_state

	# this gives some in-air control if jumping from standing still
	if (input_dir != Vector2.ZERO and player.velocity.length() < player.walk_back_speed) or !input_dir:
		if direction:
			player.velocity.x = direction.x * move_speed
			player.velocity.z = direction.z * move_speed
		else:
			player.velocity.x = move_toward(player.velocity.x, 0, move_speed)
			player.velocity.z = move_toward(player.velocity.z, 0, move_speed)

	# this allows players to jump into ledge grabs
	if Input.is_action_pressed(player.JUMP) && player.can_climb && player.allow_climb:
		if player.check_climbable():
			return grab_state

	return null
