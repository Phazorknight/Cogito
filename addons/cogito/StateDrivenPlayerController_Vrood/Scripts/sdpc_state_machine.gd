extends Node
class_name SDPCStateMachine


@export var initial_state: SDPCState

var current_state: SDPCState
var prior_state: SDPCState


func initialize(parent: CharacterBody3D):
	if parent is not CogitoSDPC:
		push_warning("State Machines are Optimized for use with CogitoSDPC")
	for child in get_children():
		if child is not SDPCState:
			push_error("Only SDPC States may be Children of the SDPCStateMachine")
		else:
			child.parent = parent

	change_state(initial_state)



func change_state(new_state: SDPCState) -> void:
	if current_state:
		# Remember the last State we passed through
		prior_state = current_state
		current_state.exit()
	current_state = new_state
	current_state.prior_state = prior_state
	current_state.enter()


func process_physics(delta: float) -> void:
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)

func process_inputs(event: InputEvent) -> void:
	var new_state = current_state.process_inputs(event)
	if new_state:
		change_state(new_state)

func process_frames(delta: float) -> void:
	var new_state = current_state.process_frames(delta)
	if new_state:
		change_state(new_state)
