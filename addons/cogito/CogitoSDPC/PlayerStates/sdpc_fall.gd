class_name SDPCStateFall
extends SDPCState

@export_group("State Connections")
@export var idle_state: SDPCStateIdle
@export var move_state: SDPCStateMove
@export var grab_state: SDPCStateGrab


var direction : Vector3 = Vector3.ZERO


func enter() -> void:
	super()
	player.view_bobbing_amount = player.default_view_bobbing_amount
	player.is_affected_by_gravity = true


func process_physics(delta: float) -> SDPCState:
	# Land
	if player.is_on_floor():
		state_machine.change_state(state_machine.stored_state)

	# If no input, we'll cancel out any other stored_states (i.e. Sprinting)
	if not player.input_direction:
		return move_state


	if Input.is_action_pressed(player.JUMP) && player.can_climb && player.allow_climb:
		if player.check_climbable():
			return grab_state

	return null
