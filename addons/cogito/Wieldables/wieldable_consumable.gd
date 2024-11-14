extends CogitoWieldable

@export var consumable_effects : Array[ConsumableEffect]

var player_inventory : CogitoInventory
var item_slot : InventorySlotPD

# Function called when wieldable is unequipped.
func equip(_player_interaction_component: PlayerInteractionComponent):
	player_interaction_component = _player_interaction_component
	player_inventory = player_interaction_component.get_parent().inventory_data
	item_slot = get_slot_reference()
	player_interaction_component.updated_wieldable_data.emit(null,0,null)
	
	animation_player.play(anim_equip)
	#await get_tree().create_timer(animation_player.current_animation_length).timeout
	
	item_reference.is_being_wielded = false
	player_interaction_component.change_wieldable_to(null)
	
	if wieldable_mesh:
		wieldable_mesh.hide()


func apply_effects():
	for effect in consumable_effects:
		effect.use(player_interaction_component.get_parent())
	
	### Reduce the stack of the dart items:
	if item_slot:
		item_slot.quantity -= 1
		if item_slot.quantity < 1:
			player_inventory.remove_slot_data(item_slot)
			
	player_inventory.inventory_updated.emit(player_inventory)


# Function to get item slot
func get_slot_reference() -> InventorySlotPD:
	var slot_reference : InventorySlotPD
	if player_inventory != null:
		for slot in player_inventory.inventory_slots:
			if slot != null and slot.inventory_item.name == item_reference.name:
				slot_reference = slot
				
	return slot_reference
