extends SDPCState

@export var idle_state: SDPCState
@export var move_state: SDPCState
@export var grab_state: SDPCState

var direction : Vector3 = Vector3.ZERO


func enter() -> void:
	super()
	player.view_bobbing_amount = player.default_view_bobbing_amount
	player.is_affected_by_gravity = true


func process_physics(delta: float) -> SDPCState:
	if player.is_on_floor():
		get_parent().change_state(get_parent().stored_state)
	
	if not player.input_direction:
		return move_state
	
	if Input.is_action_pressed(player.JUMP) && player.can_climb && player.allow_climb:
		if player.check_climbable():
			return grab_state

	return null
