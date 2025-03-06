@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_InteractionComponent.svg")
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

@export_category("Attribute Checks")
#@export var apply_attribute_check : bool = false

enum AttributeCheck {NONE, FAIL_MESSAGE, HIDE_INTERACTION}
@export var attribute_check : AttributeCheck

@export var attribute_to_check : String
@export var min_value_to_pass : float
@export var message_on_pass: String
@export var message_on_fail: String

@export var attribute_effects : Array[ConsumableEffect] 


func check_attribute(player_interaction_component: PlayerInteractionComponent) -> bool:
	if !attribute_to_check:
		CogitoGlobals.debug_log(true,"InteractionComponent.gd", "attribute_to_check was null!")
		return false
	
	var fetched_attribute : CogitoAttribute
	fetched_attribute = player_interaction_component.player.player_attributes.get(attribute_to_check)
	
	if fetched_attribute == null:
		CogitoGlobals.debug_log(true,"InteractionComponent.gd", "attribute_to_check (" + attribute_to_check + ") was not found in player_attributes!")
		return false
	
	CogitoGlobals.debug_log(true,"InteractionComponent.gd", "attribute_check (" + attribute_to_check + "): Min value needed = " + str(min_value_to_pass) + ". Current value = " + str(fetched_attribute.value_current) )
	
	if fetched_attribute.value_current >= min_value_to_pass:
		if message_on_pass and attribute_check == AttributeCheck.FAIL_MESSAGE:
			player_interaction_component.send_hint(fetched_attribute.attribute_icon, message_on_pass)
			
		if attribute_effects:
			print(self.name, ": Attemtping to apply consumable effects...")
			for effect in attribute_effects:
				effect.use(player_interaction_component.player)
				
		return true
	else:
		if message_on_pass and attribute_check == AttributeCheck.FAIL_MESSAGE:
			player_interaction_component.send_hint(fetched_attribute.attribute_icon, message_on_fail)
		return false
