extends Node
class_name SDPCState

## Dependency Injections
var parent: CogitoSDPC
var prior_state: SDPCState


func enter() -> SDPCState:
	return null


func exit() -> SDPCState:
	return null


func process_physics(delta: float) -> SDPCState:
	return null


func process_frames(delta: float) -> SDPCState:
	return null

func process_inputs(event: InputEvent) -> SDPCState:
	return null
