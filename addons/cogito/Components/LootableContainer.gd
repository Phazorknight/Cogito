## Handles loot generation within a CogitoContainer. Can be customizable with additional parameters.
class_name LootableContainer extends Node

@export_category("Master Control")
## Enables or disables the lootable container's functionality.
@export var enabled = true
## Container this component belongs to and will handle its inventory.
@export var container: CogitoContainer

@export_category("Loot Table Configuration")
## Specifies which loot table should be used to spawn items from.
@export var loot_table: LootTable
## Variable that determines how many items will be dropped from the chance and quest items specified in the loot table. Chance and quest drop items will be joined and rolled this many times. Guaranteed items do not count towards this limit and will always drop regardless. Note that you can run out of screen space in containers if you add more than 64 items total.
@export var amount_of_items_to_drop: int = 1

@export_category("Execution Configuration")
## Handles the respawning logic for inventory of CogitoContainer.
@export var inventory_respawning_logic := InventoryRespawningLogic.NONE:
	set(value):
		inventory_respawning_logic = value
		notify_property_list_changed()
## Respawn timer is calculated based on the values below. With all values converted to seconds and added together to generate a final timer.
@export_group("Respawn Timer")
## Respawn timer days component. Will be added as days 86400 seconds to final timer calculation.
@export_range(0, 30, 1, "suffix:days") var respawn_timer_days :float = 0.0
## Respawn timer used by the timed respawning function.
@export_range(0, 24, 1, "suffix:hours") var respawn_timer_hours :float = 0.0
## Respawn timer used by the timed respawning function.
@export_range(0, 60, 1, "suffix:minutes") var respawn_timer_minutes :float = 1.0
## Respawn timer used by the timed respawning function.
@export_range(0, 60, 1, "suffix:seconds") var respawn_timer_seconds :float = 0.0

enum InventoryRespawningLogic {
NONE, ## Contents of the container will not respawn. It will be safe for player to put his items in and out after the initialization.
TIMED_RESPAWN, ## Contents of the container will respawn upon the expiration of the timer. This will reset the inventory and reroll new items from the loot table provided.
}

# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager
var _player_inventory: CogitoInventory
var _player_interaction_component: PlayerInteractionComponent

## Array for loot table items that do not have any drop type selected. These items are not to be dropped.
var none: Array[Dictionary] = []
## Array for loot table items that are always guaranteed to be dropped and do not count towards maximum item drops.
var guaranteed_drops_table: Array[Dictionary] = []
## Array for loot table items that are chance based drops. These are limited by the amount_of_items_to_drop_variable.
var chance_drops_table: Array[Dictionary] = []
## Array for loot table items that are dropped only when the player is on the specific quest these items belong.
var quest_drops_table: Array[Dictionary] = []
## Respawn timer calculated value.
var calculated_respawn_timer: float
## CogitoContainer's inventory component.
var inventory_to_populate:CogitoInventory
## Contains the finalized array which will be sent to roll items.
var finalized_items: Array[Dictionary]
## Array to merge chance and quest drops in. TODO check the feasibility of a separate quest item drop thread.
var merged_array: Array[Dictionary]


func _ready() -> void:

	# Let's add the container we are a child of to a group called lootable_container
	if container:
		container.add_to_group("lootable_container")
		inventory_to_populate = container.inventory_data
	
	# Set up player references during the initialization because I don't want to globalize these.	
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)
	_player_inventory = _player.inventory_data
	_player_interaction_component = _player.player_interaction_component
	
	# Sort items by drop types
	## Array that stores the actual contents of the whole loot table resource.
	var loot_to_generate = loot_table.contents
	if loot_to_generate:
		for index in loot_to_generate:
			match index.DropType:
				0:
					none.append(index)
					push_warning("Loot table contains items with drop type set to none, these items will not be dropped.")
				1:
					guaranteed_drops_table.append(index)
				2:
					chance_drops_table.append(index)
				4:
					quest_drops_table.append(index)
	else:
		push_warning("Loot table is not set up. Loot Component will not function.")
		
	print(
		"None Size: " + str(none.size()) + str(none) + 
		" Always Size: " + str(guaranteed_drops_table.size()) + str(guaranteed_drops_table) +
		" Chance Size: " + str(chance_drops_table.size()) + str(chance_drops_table) +
		" Quest Size: " + str(quest_drops_table.size()) + str(quest_drops_table) 
		)
		
	_handle_inventory() # initial spawning
	_handle_respawning() # respawning


## Handle Inventory
func _handle_inventory():
	
	if chance_drops_table.size() > 0:
		merged_array.append_array(chance_drops_table)
	if quest_drops_table.size() > 0:
		merged_array.append_array(quest_drops_table)
	
	finalized_items = _roll_for_randomized_items(merged_array)
	
	if guaranteed_drops_table.size() > 0:
		finalized_items.append_array(guaranteed_drops_table)
		
	_populate_the_container(inventory_to_populate, finalized_items)


## Checks for given InventoryPD item against player inventory, returns true if there is a copy of a unique item, false if there isn't.
func _is_unique_found(item: InventoryItemPD):
	var _loot_bags: Array[Node] = get_tree().get_nodes_in_group("loot_bag")
	var _loot_bags_slots: Array[InventoryItemPD]
	var _player_inventory_slots: Array[InventoryItemPD] = _player_inventory.get_all_items()
	var _lookup_merge: Array[InventoryItemPD]
	
	_loot_bags.append_array(get_tree().get_nodes_in_group("lootable_containers"))
	
	if _loot_bags.size() > 0:
		for i in _loot_bags:
			_loot_bags_slots.append_array(i.inventory_data.get_all_items())
	
	_lookup_merge.append_array(_player_inventory_slots)
	_lookup_merge.append_array(_loot_bags_slots)
	
	for _slot in _lookup_merge:
		if _slot.is_unique:
			return true
	return false


# Calculate the proper value for the timer component
func _calculate_timer_value() -> float:
	var calculated_respawn_timer: float
	calculated_respawn_timer = (respawn_timer_days * 86400.0) + (respawn_timer_hours * 3600.0) + (respawn_timer_minutes * 60.0) + respawn_timer_seconds
	return calculated_respawn_timer

## Counts given quest items within player's inventory. Returns an integer.
func _count_quest_items(item: InventoryItemPD) -> int:
	var _loot_bags: Array[Node] = get_tree().get_nodes_in_group("loot_bag")
	var _loot_bags_slots: Array[InventoryItemPD]
	var _player_inventory_slots: Array[InventoryItemPD] = _player_inventory.get_all_items()
	var _lookup_merge: Array[InventoryItemPD]
	
	_loot_bags.append_array(get_tree().get_nodes_in_group("lootable_containers"))
	
	if _loot_bags.size() > 0:
		for i in _loot_bags:
			_loot_bags_slots.append_array(i.inventory_data.get_all_items())
	
	_lookup_merge.append_array(_player_inventory_slots)
	_lookup_merge.append_array(_loot_bags_slots)
	
	var _count: int
	for _slot in _lookup_merge:
		if _slot == item:
			_count += 1 
	print(_count)
	return _count


## Rolls for a dictionary entry from loot table entry. Returns an array of dictionary.
func _roll_for_randomized_items(_items: Array[Dictionary]) -> Array[Dictionary]:
	## Using engine's own rng component which is requires 4.3+.
	var _rng = RandomNumberGenerator.new()
	## Array of dictionary that stores the results.
	var _result: Array[Dictionary] = []
	## InventoryItemPD's of the passed loot table.
	var _inventory_items = []
	## Mapped float array for the weights of the loot table.
	var _item_weights: PackedFloat32Array = []
	## Failsafe counter, will break the while loop when it hits 1000 iterations.
	var _failsafe: int = 0
		
	_inventory_items = _items.map(func (k): return k)
	_item_weights = _items.map(func (k): return k.get("weight", 0.0))
	
	while _result.size() < amount_of_items_to_drop - 1:
		
		## Winning loot table entry which will be added to a separate array.
		var _winner = _inventory_items[_rng.rand_weighted(_item_weights)]
		
		# Handle Unique Items
		if _winner["inventory_item"].is_unique: # A unique item means there can be only one, highlander style. So it will not drop as long as player holds it in his inventory. We could scour all inventories to find a copy but I think that falls beyond the intended scope of the property.
			if not _is_unique_found(_winner["inventory_item"]): # Check player's inventory and other loot bags for a copy.
				if not _result.has(_winner): # Check if we've already have a copy of this unique item waiting to be dropped.
					_result.append(_winner) 
		
		# Handle Quest Items			
		elif _winner.has("quest_id"): # If winner is a quest item
			print("Quest ID: " + str(_winner.get("quest_id")) + " Quest Item Total Count: " + str(_winner.get("quest_item_total_count")))
			if _count_quest_items(_winner["inventory_item"]) >= _winner.get("quest_item_total_count", 1): # Check inventory and already spawned loot bags for a count and compare to maximum allowed count
				print("Maximum amount of quest items reached. Moving on.")
				continue
			else: # If quest item count did not reach the maximum amount
				if CogitoQuestManager.active.get_ids_from_quests().has(_winner["quest_id"]):
					if _result.has(_winner): # Check if the final array has already this quest item waiting for drop
						if _result.count(_winner) + _count_quest_items(_winner["inventory_item"]) >= _winner.get("quest_item_total_count", 1): # Check if new copy would go over the maximum limit
							continue
						else: # If it wouldn't go over the limit, create a new copy
							_result.append(_winner)
						print("You've got a quest item.")
					else: # Final array does not have a copy of this quest item awating drop
						if not _count_quest_items(_winner["inventory_item"]) >= _winner.get("quest_item_total_count", 1): # Final check for the maximum limit
							_result.append(_winner)
		
		# Handle everything else				
		else:
			_result.append(_winner) # Ordinary drops get added without scrunity.
		
		_failsafe += 1
		
		if _failsafe > 1000: # Just in case there is a problem with the variables, we don't fall into infinite loop.
			break
			
			
	print("Amount of items in results array: " + str(_result.size()))
	print("Array contains these items:")
	for i in _result:
		print(i.get("name"))
		
	print("Array took " + str(_failsafe) + " tries to complete.")
	
	return _result


## Populates the spawned container with the rolled items.
func _populate_the_container(_inventory: CogitoInventory, _items: Array[Dictionary]):
	## Index value that is iterated independently of the for loops it is used inside.
	var _index :int =  0
	## Dictionary array's size which is passed to the function during call.
	var _item_count: int = _items.size()
	## InventorySlotPD count of the inventory that is passed during function call.
	var slots: Array[InventorySlotPD] = _inventory.inventory_slots
	var inventory_x: int
	var inventory_y: int
	
	# if we are respawning, better clear out the contents.
	if slots.size() > 0:
		if _player_hud.inventory_interface.is_inventory_open:
			if _player_hud.inventory_interface.get_external_inventory() == container:
				_player_hud.inventory_interface.clear_external_inventory()
				
		for slot in slots:
			_inventory.null_out_slots(slot)

	_inventory.inventory_size.x = 8
	_inventory.inventory_size.y = _item_count / 8 + 1
	inventory_x = 8
	inventory_y = _item_count / 8 + 1
	slots.resize(inventory_x * inventory_y)
	_inventory.first_slot = slots[0]
	print("Inventory size set to: " + str(slots.size()))
	for i in _item_count:
		slots[i] = InventorySlotPD.new()
		
	for item in _items:
		slots[_index].inventory_item = item.get("inventory_item")
		slots[_index].set_quantity(randi_range(item.get("quantity_min", 1), item.get("quantity_max", 1)))
		slots[_index].origin_index = _index
		slots[_index].resource_local_to_scene = true
		slots[_index].inventory_item.resource_local_to_scene = true
		_index += 1
	
	_index = 0
	for i in slots:
		print("Slot number: " + str(_index) + " holds item: " + str(slots[_index]))
		_index += 1
	
	if _player_hud.inventory_interface.is_inventory_open:
		if _player_interaction_component.last_interacted_node.get_parent() == container:
			_player_hud.inventory_interface.set_external_inventory(container)


## Handles the respawning logic for the inventory_respawning_logic enum.
func _handle_respawning():
	match inventory_respawning_logic:
		InventoryRespawningLogic.NONE:
			return
		InventoryRespawningLogic.TIMED_RESPAWN:
			var _timer: Timer = Timer.new()
			add_child(_timer)
			_timer.wait_time = _calculate_timer_value()
			_timer.one_shot = false
			_timer.timeout.connect(_handle_inventory)
			_timer.start()
			print("Timer created for: " + str(_timer.wait_time) + " seconds.")
