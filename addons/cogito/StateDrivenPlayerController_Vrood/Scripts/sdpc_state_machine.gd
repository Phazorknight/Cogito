@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoProperties.svg")
extends Node
class_name SDPCStateMachine

## To Do, Setup as Onready
@export var initial_state: SDPCState
@export var ladder_climb_state: LadderClimbingSDPCState
@export var sitting_state: SittingSDPCState
@export var paused_state: PausedSDPCState
var current_state: SDPCState
var prior_state: SDPCState


func initialize(parent: CharacterBody3D):
	if parent is not CogitoSDPC:
		push_warning("SDPCStateMachine initialized without CogitoSDPC. Some features may not work as expected.")
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
	current_state.prior_state = prior_state # give the individual states Reference to past States
	current_state.enter()


func process_physics(delta: float) -> void:
	# States will return null unless a state change is required
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)

func process_handled_inputs(event: InputEvent) -> void:
	# States will return null unless a state change is required
	var new_state = current_state.process_handled_inputs(event)
	if new_state:
		change_state(new_state)

func process_unhandled_inputs(event: InputEvent) -> void:
	var new_state = current_state.process_unhandled_inputs(event)
	if new_state:
		change_state(new_state)


func process_frames(delta: float) -> void:
	var new_state = current_state.process_frames(delta)
	if new_state:
		change_state(new_state)
