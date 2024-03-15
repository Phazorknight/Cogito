extends Node3D
class_name InteractionComponent

signal was_interacted_with(interaction_text,input_map_action)

@export var input_map_action : String
@export var interaction_text : String
@export var is_disabled : bool = false
