class_name SDPCStateCrouch
extends SDPCState

@export_group("State Connections")
@export var idle_state: SDPCStateIdle
@export var move_state: SDPCStateMove
@export var crouch_move_state: SDPCStateCrouchMove

func enter() -> void:
	player.is_crouched = true
	player.is_moving = false

func process_input(event: InputEvent) -> SDPCState:
	if player.input_direction:
		return crouch_move_state

	# This method assumes hold to crouch and assumes that is we want Jump to also cancel crouching
	if Input.is_action_pressed(player.JUMP) or Input.is_action_just_released(player.CROUCH):
		player.stand_up()
		player.is_crouched = false

		if player.input_direction:
			return move_state
		else:
			return idle_state

	else:
		return null
