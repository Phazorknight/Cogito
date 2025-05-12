extends Node

# These will be autofilled by the StateMachine
var Host # is our Character node (parent of StateMachine)
var States # is the StateMachine itself

@export var stance_raised_fists : String = "RaisedFists"
@export var stance_neutral : String = "Neutral"

var stance_active : bool = false

func _state_enter():
	var upper_body_state = Host.animation_tree.get("parameters/UpperBodyState/playback")
	if !stance_active:
		CogitoGlobals.debug_log(true, "NPC State Switch Stance", "Switching stance to " + stance_raised_fists)
		upper_body_state.travel(stance_raised_fists)
		stance_active = true
	else:
		CogitoGlobals.debug_log(true, "NPC State Switch Stance", "Switching stance to " + stance_neutral)
		upper_body_state.travel(stance_neutral)
		stance_active = false
	
	States.load_previous_state()

func _state_exit():
	pass

func _physics_process(_delta):
	pass
