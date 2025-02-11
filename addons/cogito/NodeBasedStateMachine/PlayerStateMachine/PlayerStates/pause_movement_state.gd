class_name PauseMovementState
extends CogitoState



# Called when entering this state.
func enter_state(character_controller: CogitoCharacterStateMachine):
	super(character_controller)
	character.is_movement_paused = true
	# Connect the state to the pause menu signal from the Character Controller
	character._on_pause_menu_resume.connect(_on_resume)
	# Only show mouse cursor if input device is KBM
	if character is CogitoPlayerStateMachine and InputHelper.device_index == -1:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# Called when exiting this state.
func exit_state():
	character.is_movement_paused = false
	if character is CogitoPlayerStateMachine:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _on_resume():
	exit_state()
