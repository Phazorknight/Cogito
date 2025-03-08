class_name DeadSDPCState
extends SDPCState


func enter() -> SDPCState:
	parent.is_dead = true
	parent.player_interaction_component.on_death()
	return null

func exit() -> SDPCState:
	parent.is_dead = false
	return null
