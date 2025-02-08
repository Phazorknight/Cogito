extends SDPCState

@export var fall_state: SDPCState
@export var jump_state: SDPCState
@export var move_state: SDPCState
@export var crouch_state: SDPCState
@export var sprint_state: SDPCState

func enter() -> void:
	super()


func process_input(event: InputEvent) -> SDPCState:
	if player.can_jump:
		if event.is_action_pressed(player.JUMP) && player.is_on_floor() && player.allow_jump:
			return jump_state

	if player.can_crouch && player.allow_crouch:
		if event.is_action_pressed(player.CROUCH) && player.is_on_floor():
			return crouch_state
	
	return null


func process_physics(delta: float) -> SDPCState:
	var input_dir := player.input_direction
	
	if !player.is_on_floor():
		return fall_state
	
	if input_dir && player.can_sprint:
		if Input.is_action_just_pressed(player.SPRINT) && player.allow_sprint:
			return sprint_state
		else:
			return move_state
	
	return null
