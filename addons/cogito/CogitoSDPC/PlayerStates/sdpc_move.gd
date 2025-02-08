extends SDPCState

@export var fall_state: SDPCState
@export var idle_state: SDPCState
@export var jump_state: SDPCState
@export var sprint_state: SDPCState
@export var crouch_state: SDPCState

@export var walk_speed : float = 2

var direction : Vector3 = Vector3.ZERO
var input_dir : Vector2 = Vector2.ZERO


func enter() -> void:
	super()
	player.view_bobbing_amount = player.default_view_bobbing_amount


func process_input(event: InputEvent) -> SDPCState:
	if Input.is_action_just_pressed(player.SPRINT) && player.allow_sprint:
		return sprint_state
	
	if event.is_action_pressed(player.JUMP) && player.is_on_floor() && player.allow_jump:
		return jump_state
	
	if player.can_crouch && player.allow_crouch:
		if event.is_action_pressed(player.CROUCH) && player.is_on_floor():
			return crouch_state
	
	return null


func process_physics(delta: float) -> SDPCState:
	input_dir = player.input_direction
	direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if input_dir.y > 0:
		move_speed = player.walk_back_speed
	else:
		if player.movement_strength == 0:
			move_speed = player.walk_speed
		else:
			move_speed = player.walk_speed * player.movement_strength
	
	if direction:
		player.velocity.x = direction.x * move_speed
		player.velocity.z = direction.z * move_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, move_speed)
		player.velocity.z = move_toward(player.velocity.z, 0, move_speed)
		
		return idle_state
	
	if player.velocity.y < 0:
		get_parent().stored_state = self
		return fall_state
	
	return null
