class_name PausedSDPCState
extends SDPCState



func enter() -> SDPCState:
	return null


func exit() -> SDPCState:
	return prior_state


func process_physics(delta: float) -> SDPCState:
	return null


func process_frames(delta: float) -> SDPCState:
	return null

func process_handled_inputs(event: InputEvent) -> SDPCState:
	return null

func process_unhanled_inputs(event: InputEvent) -> SDPCState:
	return null
