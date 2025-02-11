
class_name CogitoCharacterStateMachine
extends CharacterBody3D

var current_state: CogitoState
var old_state: CogitoState

# Called by CogitoStates
func change_state(new_state_name: String):
	if current_state:
		old_state = current_state
		current_state.exit_state()
	current_state = get_node(new_state_name)
	if current_state: # checking to make sure the new state exists
		current_state.enter_state(self)

func _physics_process(delta: float) -> void:
	_state_machine_process(delta)


func _state_machine_process(delta):
	if current_state:
		current_state.handle_input(delta)
