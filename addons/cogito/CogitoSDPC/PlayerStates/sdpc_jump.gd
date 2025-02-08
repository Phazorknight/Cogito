extends SDPCState

@export_group("State Connections")
@export var fall_state: SDPCState
@export var idle_state: SDPCState
@export var move_state: SDPCState

@export_group("State Properties")
@export var jump_exhaustion: float

var stamina_attribute_reference: CogitoStaminaAttribute

func enter() -> void:
	super()
	if player.is_crouched:
		player.stand_up()

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
	
	# this gives some in-air control if jumping from standing still
	if (input_dir != Vector2.ZERO and player.velocity.length() < player.walk_back_speed) or !input_dir:
		if direction:
			player.velocity.x = direction.x * move_speed
			player.velocity.z = direction.z * move_speed
		else:
			player.velocity.x = move_toward(player.velocity.x, 0, move_speed)
			player.velocity.z = move_toward(player.velocity.z, 0, move_speed)
	
	return null
