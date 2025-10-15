extends InteractionComponent
class_name CogitoWieldableInteractionComponent

### interaction to check for wieldables.
@export var required_wieldable : WieldableItemPD
## Sound that plays when interacted.
@export var interaction_sound : AudioStream

## Action to perform
enum WieldableAction {CHARGE, RELOAD, CONTAINER_ITEM, CUSTOM}
@export var wieldable_action : WieldableAction
@export var container_item_to_dispense : ContainerItemContent
### If above is set to custom, method to call on Wieldable
@export var custom_method : String
@export var custom_parameter : int

## Only show this interaction prompt if the player is wielding
@export var require_wieldable_to_show : bool = false


func interact(_player_interaction_component:PlayerInteractionComponent):
	if !is_disabled:
		if attribute_check == AttributeCheck.NONE:
			if check_for_wieldable(_player_interaction_component):
				perform_wieldable_interaction(_player_interaction_component)
			was_interacted_with.emit(interaction_text,input_map_action)
		else:
			if check_attribute(_player_interaction_component):
				if check_for_wieldable(_player_interaction_component):
					perform_wieldable_interaction(_player_interaction_component)
				was_interacted_with.emit(interaction_text,input_map_action)


func check_for_wieldable(_player_interaction_component: PlayerInteractionComponent) -> bool:
	if !_player_interaction_component.is_wielding:
		_player_interaction_component.send_hint(null, "You aren't holding anything!")
		return false
	if _player_interaction_component.equipped_wieldable_item == required_wieldable:
		return true
	else:
		_player_interaction_component.send_hint(null, "You are holding the wrong thing!")
		return false


func perform_wieldable_interaction(_player_interaction_component: PlayerInteractionComponent):
	print("WieldableInteraction: Wieldable found. Attempting action...")
	match wieldable_action:
		WieldableAction.RELOAD:
			pass
		WieldableAction.CHARGE:
			pass
		WieldableAction.CONTAINER_ITEM:
			print("WieldableInteraction: Attempting to change content to ", container_item_to_dispense.content_name)
			_player_interaction_component.equipped_wieldable_item.change_content_to(container_item_to_dispense)
		WieldableAction.CUSTOM:
			print("Attempting to use custom method ", custom_method, " with parameter ", custom_parameter)
			var custom_callable = Callable(_player_interaction_component.equipped_wieldable_item, custom_method)
			custom_callable.call(custom_parameter)
	
	if interaction_sound:
		Audio.play_sound_2d(interaction_sound)


func _on_object_state_change(_interaction_text: String):
	interaction_text = _interaction_text
