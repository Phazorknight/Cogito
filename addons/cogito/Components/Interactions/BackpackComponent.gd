extends InteractionComponent
class_name BackpackComponent

@export_group("Backpack Settings")
## Sound that plays when backpack is interacted with
@export var sound_on_use: AudioStream
## The new inventory grid size.
@export var new_inventory_size : Vector2i = Vector2i(8,6)

var temp_item_array : Array[InventorySlotPD]

func interact(_player_interaction_component:PlayerInteractionComponent):
	update_player_inventory(_player_interaction_component.player)
	
	if sound_on_use:
		Audio.play_sound(sound_on_use)
		
	get_parent().queue_free()


func update_player_inventory(player: CogitoPlayer):
	var player_inventory = player.inventory_data
	
	# Grab all existing items of player inventory and add them to temp item array
	# This also removes them from the player inventory
	temp_store_items(player_inventory)
	
	player_inventory.inventory_size = new_inventory_size
	player_inventory.inventory_slots.resize(player_inventory.inventory_size.x * player_inventory.inventory_size.y)
	
	# Re-add items to player inventory from temp item array
	give_back_items(player_inventory)
	
	player_inventory.force_inventory_update()


func temp_store_items(_passed_inventory: CogitoInventory) -> void:
	temp_item_array.clear()
	
	var inventory = _passed_inventory
	for slot_data in inventory.inventory_slots:
		if slot_data != null:
			temp_item_array.append(slot_data)
			CogitoGlobals.debug_log(true,"BackpackComponent", slot_data.inventory_item.name + " added to temp_item_array.")
			inventory.remove_item_from_stack(slot_data)


func give_back_items(_passed_inventory: CogitoInventory) -> void:
	var inventory = _passed_inventory
	
	for item in temp_item_array:
		inventory.pick_up_slot_data(item)
		CogitoGlobals.debug_log(true,"BackpackComponent", item.inventory_item.name + " added  back to player inventory.")
