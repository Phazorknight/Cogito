## Handles loot generation from passed loot table and returns an array of dictionary.
class_name LootGenerator extends Node


## Enables the debug prints. There are quite a few so output may be crowded.
@onready var debug_prints: bool = CogitoGlobals.cogito_settings.loot_generator_debug

# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager
var _player_inventory: CogitoInventory

# Arrays to sort items into
## Array for loot table items that do not have any drop type selected. These items are not to be dropped.
var none: Array[LootDropEntry] = []
## Array for loot table items that are always guaranteed to be dropped and do not count towards maximum item drops.
var guaranteed_drops_table: Array[LootDropEntry] = []
## Array for loot table items that are chance based drops. These are limited by the amount_of_items_to_drop_variable.
var chance_drops_table: Array[LootDropEntry] = []
## Array for loot table items that are dropped only when the player is on the specific quest these items belong.
var quest_drops_table: Array[LootDropEntry] = []


## Generate loot by passing a loot table and amount of items to generate.
func generate(loot_table: LootTable, amount: int, debug: bool = false) -> Array[LootDropEntry]:
	debug_prints = debug
	
	var input_array: Array[LootDropEntry] = []
	var output_array: Array[LootDropEntry] = []
	
	if loot_table != null and amount > 0:
		_set_up_references()
		_sort_loot_table(loot_table)
		
		if chance_drops_table.size() > 0:
			input_array.append_array(chance_drops_table)
			
		if quest_drops_table.size() > 0:
			input_array.append_array(quest_drops_table)
			
		output_array = _roll_for_randomized_items(input_array, amount)
			
		if guaranteed_drops_table.size() > 0:
			output_array.append_array(guaranteed_drops_table)
			
	return output_array


## Set up references to player in order to query loot bags and player inventory so we can check for unique and quest drops.
func _set_up_references():
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)
	_player_inventory = _player.inventory_data


## Sort the loot table into neat little arrays.
func _sort_loot_table(loot_table: LootTable):
	## Array that stores the actual contents of the whole loot table resource.
	var loot_to_generate = loot_table.drops
	if loot_to_generate:
		for index in loot_to_generate:
			match index.droptype:
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
	

	CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", 
		"None Size: " + str(none.size()) + str(none) + 
		" Always Size: " + str(guaranteed_drops_table.size()) + str(guaranteed_drops_table) +
		" Chance Size: " + str(chance_drops_table.size()) + str(chance_drops_table) +
		" Quest Size: " + str(quest_drops_table.size()) + str(quest_drops_table) 
		)


## Checks for given InventoryPD item against player inventory, loot bags, and lootable containers, returns true if there is a copy of a unique item, false if there isn't.
func _is_unique_found(item: InventoryItemPD):
	var _loot_bags: Array[Node] = get_tree().get_nodes_in_group("loot_bag")
	var _spawned_items: Array[Node] = get_tree().get_nodes_in_group("spawned_loot_items")
	_loot_bags.append_array(get_tree().get_nodes_in_group("lootable_containers"))
	
	var _loot_bags_slots: Array[InventoryItemPD] = []
	var _spawned_items_in_scene: Array[InventoryItemPD] = []
	var _player_inventory_slots: Array[InventoryItemPD] = _player_inventory.get_all_items()
	var _lookup_merge: Array[InventoryItemPD] = []
	
	if _loot_bags.size() > 0:
		for i in _loot_bags:
			_loot_bags_slots.append_array(i.inventory_data.get_all_items())
	
	if _spawned_items.size() > 0:
		for i in _spawned_items:
			var children = []
			children = i.get_children()
			for child in children:
				if child is PickupComponent:
					_spawned_items_in_scene.append(child.slot_data.inventory_item)
	
	_lookup_merge.append_array(_player_inventory_slots)
	_lookup_merge.append_array(_loot_bags_slots)
	_lookup_merge.append_array(_spawned_items_in_scene)
	
	for _slot in _lookup_merge:
		if _slot.is_unique:
			return true
	return false


## Counts given quest items within player's inventory, loot bags, and lootable containers. Returns an integer.
func _count_quest_items(item: InventoryItemPD) -> int:
	var _loot_bags: Array[Node] = get_tree().get_nodes_in_group("loot_bag")
	_loot_bags.append_array(get_tree().get_nodes_in_group("lootable_containers"))
	var _spawned_items: Array[Node] = get_tree().get_nodes_in_group("spawned_loot_items")

	var _loot_bags_slots: Array[InventoryItemPD]
	var _spawned_items_in_scene: Array[InventoryItemPD] = []
	var _player_inventory_slots: Array[InventoryItemPD] = _player_inventory.get_all_items()
	var _lookup_merge: Array[InventoryItemPD]
	
	if _loot_bags.size() > 0:
		for i in _loot_bags:
			_loot_bags_slots.append_array(i.inventory_data.get_all_items())
			
	if _spawned_items.size() > 0:
		for i in _spawned_items:
			var children = []
			children = i.get_children()
			for child in children:
				if child is PickupComponent:
					_spawned_items_in_scene.append(child.slot_data.inventory_item)
	
	_lookup_merge.append_array(_player_inventory_slots)
	_lookup_merge.append_array(_loot_bags_slots)
	_lookup_merge.append_array(_spawned_items_in_scene)
	
	var _count: int
	for _slot in _lookup_merge:
		if _slot == item:
			_count += 1 
	CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", "Quest items count is: " + str(_count))
	return _count


## Rolls for a dictionary entry from loot table entry. Returns an array of dictionary.
func _roll_for_randomized_items(_items: Array[LootDropEntry], _amount: int) -> Array[LootDropEntry]:
	## Using engine's own rng component which is requires 4.3+.
	var _rng = RandomNumberGenerator.new()
	## Array of dictionary that stores the results.
	var _result: Array[LootDropEntry] = []
	## InventoryItemPD's of the passed loot table.
	var _inventory_items = []
	## Mapped float array for the weights of the loot table.
	var _item_weights: PackedFloat32Array = []
	## Failsafe counter, will break the while loop when it hits 1000 iterations.
	var _failsafe: int = 0
	
	if _items.is_empty():
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", "_roll_for_randomized_items(): Passed item array was empty! Returning empty lootdrop array...")
		var empty_lootdrop_array : Array[LootDropEntry] = []
		return empty_lootdrop_array
	
	_inventory_items = _items.map(func (k): return k)
	_item_weights = _items.map(func (k): return k.weight)
	
	while _result.size() < _amount:
		
		## Winning loot table entry which will be added to a separate array.
		var _winner = _inventory_items[_rng.rand_weighted(_item_weights)]
		
		# Handle Unique Items
		if _winner.inventory_item.is_unique: # A unique item means there can be only one, highlander style. So it will not drop as long as player holds it in his inventory. We could scour all inventories to find a copy but I think that falls beyond the intended scope of the property.
			if not _is_unique_found(_winner.inventory_item): # Check player's inventory and other loot bags for a copy.
				if not _result.has(_winner): # Check if we've already have a copy of this unique item waiting to be dropped.
					_result.append(_winner) 
		
		# Handle Quest Items			
		elif _winner.quest_id > -1: # If winner is a quest item
			CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", "Quest ID: " + str(_winner.quest_id) + " Quest Item Total Count: " + str(_winner.quest_item_total_count) )
			if _count_quest_items(_winner.inventory_item) >= _winner.quest_item_total_count: # Check inventory and already spawned loot bags for a count and compare to maximum allowed count
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", "Maximum amount of quest items reached. Moving on.")
				continue
			else: # If quest item count did not reach the maximum amount
				if CogitoQuestManager.active.get_ids_from_quests().has(_winner.quest_id):
					if _result.has(_winner): # Check if the final array has already this quest item waiting for drop
						if _result.count(_winner) + _count_quest_items(_winner.inventory_item) >= _winner.quest_item_total_count: # Check if new copy would go over the maximum limit
							continue
						else: # If it wouldn't go over the limit, create a new copy
							_result.append(_winner)
						CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", "You've got a quest item in loot generator.")
					else: # Final array does not have a copy of this quest item awating drop
						if not _count_quest_items(_winner.inventory_item) >= _winner.quest_item_total_count: # Final check for the maximum limit
							_result.append(_winner)
		
		# Handle everything else				
		else:
			_result.append(_winner) # Ordinary drops get added without scrunity.
		
		_failsafe += 1
		
		if _failsafe > 1000: # Just in case there is a problem with the variables, we don't fall into infinite loop.
			break
			
	if debug_prints:		
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", "Amount of items in results array: " + str(_result.size()))
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", "Array contains these items:")
		for i in _result:
			CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", i.get("name"))
		
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Generator", "Array took " + str(_failsafe) + " tries to complete.")
	
	return _result
