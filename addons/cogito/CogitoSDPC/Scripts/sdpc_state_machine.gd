# Player Controller State machine to be used with the State-driven player controller (SDPC)
extends Node
class_name SDPCStateMachine

@export var starting_state: SDPCState
@export var print_state_changes: bool = false

var stored_state: SDPCState
var current_state: SDPCState


# Initialize the state machine by giving each child state a reference to the parent object it belongs to and enter the default starting_state.
func init(player: CogitoSDPC) -> void:
	for child in get_children():
		child.player = player

	# Initialize to the default state
	change_state(starting_state)


# Change to the new state by first calling any exit logic on the current state.
func change_state(new_state: SDPCState) -> void:
	if !new_state:
		return
		
	if current_state:
		current_state.exit()

	if print_state_changes and current_state and new_state:
		print("SDPC: Changing state FROM ", current_state.name, " >===> ", new_state.name)

	current_state = new_state
	current_state.enter()


# Pass through functions for the Player to call, handling state changes as needed.
func process_physics(delta: float) -> void:
	if !current_state:
		return
	
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)


func process_input(event: InputEvent) -> void:
	if !current_state:
		return
	
	var new_state = current_state.process_input(event)
	if new_state:
		change_state(new_state)


func process_frame(delta: float) -> void:
	if !current_state:
		return
	
	var new_state = current_state.process_frame(delta)
	if new_state:
		change_state(new_state)
