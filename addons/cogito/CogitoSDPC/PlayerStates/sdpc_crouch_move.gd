class_name SDPCStateCrouchMove
extends SDPCState

@export_group("State Connections")
@export var crouch_state: SDPCStateCrouch
@export var move_state: SDPCStateMove
@export var fall_state: SDPCStateFall
@export var sprint_state: SDPCStateSprint


func enter() -> void:
	player.is_crouched = true

func exit() -> void:
	player.is_crouched = false

func process_input(event: InputEvent) -> SDPCState:

	if player.input_direction:
		# TODO: Crouch Walk
		pass

	# This assumes that we are wanting the player to only Stand from crouching
	if Input.is_action_pressed(player.JUMP):
		player.stand_up()
		return move_state


	if Input.is_action_pressed(player.SPRINT) && player.allow_sprint && player.can_sprint:
		player.stand_up()
		return sprint_state

	else:
		return null


func process_physics(delta: float) -> SDPCState:

	if !player.input_direction:
		return crouch_state

	if !player.is_on_floor():
		return fall_state

	else:
		return null
