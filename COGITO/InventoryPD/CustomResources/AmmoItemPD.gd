extends InventoryItemPD
class_name AmmoItemPD

@export_group("Ammo settings")
## The item that this item is ammunition for.
@export var target_item_ammo : WieldableItemPD = null
## The amount one item addes to the target item charge. For bullets this should be 1.
@export var reload_amount : int = 1


func use(target) -> bool:
	# Target should always be player? Null check to override using the CogitoSceneManager, which stores a reference to current player node
	if target == null or target.is_in_group("external_inventory"):
		print("Bad target pass. Setting target to", CogitoSceneManager._current_player_node)
		target = CogitoSceneManager._current_player_node
		
	if hint_text_on_use != "":
		target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
	return true
