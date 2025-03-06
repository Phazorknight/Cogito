extends InventoryItemPD
class_name CombinableItemPD

@export_group("Combinable settings")
## The name of the item that this item combines with. Caution: String has to be a perfect match, so watch casing and space.
@export var target_item_combine : String = ""
## The item that gets created when this item is combined with the one above.
@export var resulting_item : InventorySlotPD = null


func use(target) -> bool:
	# Target should always be player? Null check to override using the CogitoSceneManager, which stores a reference to current player node
	if target == null or target.is_in_group("external_inventory"):
		CogitoGlobals.debug_log(true, "CombinableItemPD", "Bad target pass. Setting target to" + str(CogitoSceneManager._current_player_node) )
		target = CogitoSceneManager._current_player_node
		
	if hint_text_on_use != "":
		target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
	return true

# Method to check if this is a combinable item.
func is_combinable():
	pass
