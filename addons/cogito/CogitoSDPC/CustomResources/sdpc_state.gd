# State to be used with the State-driven player controller (SDPC)

extends Node
class_name SDPCState

@export var animation_name: String
@export
var move_speed: float = 300

var gravity: int = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: CogitoSDPC # Hold a reference to the parent so that it can be controlled by the state


func enter() -> void:
	if animation_name: 	player.animations.play(animation_name)


func exit() -> void:
	pass


func process_input(event: InputEvent) -> SDPCState:
	return null


func process_frame(delta: float) -> SDPCState:
	return null


func process_physics(delta: float) -> SDPCState:
	return null
