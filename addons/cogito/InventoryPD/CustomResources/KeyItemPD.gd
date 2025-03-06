extends InventoryItemPD
class_name KeyItemPD

@export_group("Key settings")
# If this is checked, the key item will be removed from the inventory after it's been used on the target object.
@export var discard_after_use : bool = false


func use(target) -> bool:
	# Target should always be player? Null check to override using the CogitoSceneManager, which stores a reference to current player node
	if target == null or target.is_in_group("external_inventory"):
		CogitoGlobals.debug_log(true, "KeyItemPD", "Bad target pass. Setting target to" + str(CogitoSceneManager._current_player_node) )
		target = CogitoSceneManager._current_player_node

	if hint_text_on_use != "":
		target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
	return true
