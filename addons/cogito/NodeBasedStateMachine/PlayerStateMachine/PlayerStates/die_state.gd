extends CogitoState
class_name DieState

# Called when entering this state.
func enter_state(character_controller: CogitoCharacterStateMachine):
	super(character_controller)
	character.player_interaction_component.on_death()
	character.is_dead = true


# Called when exiting this state.
#func exit_state():
#	pass



#func handle_input(_delta):
#	pass
