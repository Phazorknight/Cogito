extends Node

# These will be autofilled by the StateMachine
var Host # is our Character node (parent of StateMachine)
var States # is the StateMachine itself

@export var idle_animation : String = ""

func _state_enter():
	CogitoGlobals.debug_log(true, "npc_state_idle.gd", "Idle state entered")

	await get_tree().create_timer(3).timeout
	
	States.goto("patrol_on_path", null)


func _state_exit():
	States.save_state_as_previous(self.name,null)
	CogitoGlobals.debug_log(true, "npc_state_idle.gd", "Idle state exiting")


func _physics_process(_delta):
	pass
