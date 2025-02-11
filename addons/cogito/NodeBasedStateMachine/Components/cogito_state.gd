#@icon("___
## A Node Based State Machine For Controlling 3D Characters
class_name CogitoState
extends Node

var character # Reference to the node that is controlled by this State

# Called when entering this state.
func enter_state(character_controller: CogitoCharacterStateMachine):
	# Store a reference to the character's StateMachine
	character = character_controller


# Called when exiting this state.
func exit_state():
	pass


func handle_input(_delta):
	pass
