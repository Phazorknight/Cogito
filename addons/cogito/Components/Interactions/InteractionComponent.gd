@icon("res://COGITO/Assets/Graphics/Editor/Icon_InteractionComponent.svg")
extends Node3D
## Base class for any interactions based on input map actions.
class_name InteractionComponent

signal was_interacted_with(interaction_text,input_map_action)

## The input map action string as defined in the Godot Project settings input map.
@export var input_map_action : String
## The text that gets displayed in the HUD interaction prompt.
@export var interaction_text : String
## Turn this on if you want this interaction to be triggered by something else than the input map action (for example by the DualInteraction component)
@export var is_disabled : bool = false
## If this is set to false, the interaction with this component will not be processed if the player has any GUI open (like the inventory, readables, keypad, etc.)
@export var ignore_open_gui : bool = true
