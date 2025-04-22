## Generates a bag of loot after death. This inventory is not a grid inventory, each dropped item will have its own slot.
class_name LootComponent extends Node3D 

@export_category("Master Control")
## Enables or disables the loot components functionality.
@export var enabled = true

@export_category("Loot Table Configuration")
## Specifies which loot table should be used to spawn items from.
@export var loot_table: LootTable
## Variable that determines how many items will be dropped from the chance and quest items specified in the loot table. Chance and quest drop items will be joined and rolled this many times. Guaranteed items do not count towards this limit and will always drop regardless. Note that you can run out of screen space in containers if you add more than 64 items total.
@export var amount_of_items_to_drop: int = 1

@export_category("Scene Object Configuration")
## Scene of the loot bag the items should be spawned inside.
@export var loot_bag_scene: PackedScene

@export_category("Execution Configuration")
## Reference to the health component to monitor for on death signal.
@export var health_component_to_monitor: CogitoHealthAttribute
## Handles the despawning logic for the loot bag.
@export var despawning_logic := DespawningLogic.NONE:
	set(value):
		despawning_logic = value
		notify_property_list_changed()
## Despawn timer used by the timed despawning function.
@export_range(0, 600, 10, "suffix:seconds") var despawn_timer :float = 60.0

enum DespawningLogic {
NONE, ## Container will not despawn and will become part of the scene. 
ONLY_EMPTY, ## Container will despawn only after player takes out the last item in it.
ONLY_TIMED, ## Container will despawn after a preset time interval started upon container creation. Note: Items present will be lost with timed despawning logic.
EMPTY_AND_TIMED ## Container will despawn after a time period as well as upon a timer expiration. Note: Items present will be lost with timed despawning logic.
}

# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager
var _player_inventory: CogitoInventory

# Arrays to sort items into
## Array for loot table items that do not have any drop type selected. These items are not to be dropped.
var none: Array[Dictionary] = []
## Array for loot table items that are always guaranteed to be dropped and do not count towards maximum item drops.
var guaranteed_drops_table: Array[Dictionary] = []
## Array for loot table items that are chance based drops. These are limited by the amount_of_items_to_drop_variable.
var chance_drops_table: Array[Dictionary] = []
## Array for loot table items that are dropped only when the player is on the specific quest these items belong.
var quest_drops_table: Array[Dictionary] = []


func _get_configuration_warnings():
	if !loot_table:
		return ["Loot table is not set. It is required for the loot component to function."]
		
func _ready() -> void:
	
	if not _validate_loot_table():
		return
	
	health_component_to_monitor.death.connect(_spawn_loot_container) ## Connect to Health Component's Death signal and trigger the function.
	
	# Set up player references during the initialization because I don't want to globalize these.	
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)
	_player_inventory = _player.inventory_data
	
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


## Spawns the loot container defined in the loot_bag_scene variable.
func _spawn_loot_container():
	## Parent node's global position
	var parent_position = get_parent().global_position
	## Loot bag scene that is instantiated during runtime.
	var spawned_loot_bag
	## Spawned loot bag's inventory component.
	var inventory_to_populate:CogitoInventory
	## Contains the finalized array which will be sent to roll items.
	var finalized_items: Array[Dictionary]
	## Array to merge chance and quest drops in. TODO check the feasibility of a separate quest item drop thread.
	var merged_array: Array[Dictionary]
	
	if enabled and amount_of_items_to_drop > 0:
		spawned_loot_bag = loot_bag_scene.instantiate()
		spawned_loot_bag.position = parent_position
		get_tree().current_scene.call_deferred("add_child", spawned_loot_bag)
		
		if !spawned_loot_bag.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
			spawned_loot_bag.toggle_inventory.connect(_player_hud.toggle_inventory_interface)

		inventory_to_populate = spawned_loot_bag.inventory_data
		spawned_loot_bag.add_to_group("loot_bag")
		print("Spawned Loot Bag: " + str(spawned_loot_bag) + "at these coordinates: " + str(spawned_loot_bag.position))
		handle_despawning(spawned_loot_bag)
		
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
	
	if _loot_bags.size() > 0:
		for i in _loot_bags:
			_loot_bags_slots.append_array(i.inventory_data.get_all_items())
	
	_lookup_merge.append_array(_player_inventory_slots)
	_lookup_merge.append_array(_loot_bags_slots)
	
	for _slot in _lookup_merge:
		if _slot.is_unique:
			return true
	return false


## Counts given quest items within player's inventory. Returns an integer.
func _count_quest_items(item: InventoryItemPD) -> int:
	var _loot_bags: Array[Node] = get_tree().get_nodes_in_group("loot_bag")
	var _loot_bags_slots: Array[InventoryItemPD]
	var _player_inventory_slots: Array[InventoryItemPD] = _player_inventory.get_all_items()
	var _lookup_merge: Array[InventoryItemPD]
	
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
	
	while _result.size() != amount_of_items_to_drop - 1:
		
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

	slots.resize(_item_count)
	_inventory.inventory_size.x = 8
	_inventory.inventory_size.y = _item_count / 8 + 1
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


## Handles the despawning logic for the despawning_logic enum.
func handle_despawning(spawned_loot_bag: CogitoContainer):
	match despawning_logic:
		DespawningLogic.NONE:
			return
		DespawningLogic.ONLY_EMPTY:
			var despawner = EmptiedDespawner.new()
			despawner.container_to_monitor = spawned_loot_bag
			spawned_loot_bag.call_deferred("add_child", despawner)
		DespawningLogic.ONLY_TIMED:
			var despawner = TimedDespawner.new()
			despawner.container_to_monitor = spawned_loot_bag
			despawner.despawn_timer = despawn_timer
			spawned_loot_bag.call_deferred("add_child", despawner)
		DespawningLogic.EMPTY_AND_TIMED:
			var emptied_despawner = EmptiedDespawner.new()
			var timed_despawner = TimedDespawner.new()
			emptied_despawner.container_to_monitor = spawned_loot_bag
			timed_despawner.container_to_monitor = spawned_loot_bag
			timed_despawner.despawn_timer = despawn_timer
			spawned_loot_bag.call_deferred("add_child", emptied_despawner)
			spawned_loot_bag.call_deferred("add_child", timed_despawner)


## Validates the loot table setup for debugging purposes.
func _validate_loot_table() -> bool:
	var errors: int = 0
	var warnings: int = 0
	for i in loot_table.contents:
		
		if i.has("inventory_item") and i.get("inventory_item") != null:
			continue
		else:
			push_error("Loot table has entries with invalid InventoryItemPD references. This will lead to a crash.")
			errors += 1
			
		if i.has("DropType") and i.get("DropType"):
			if i.has("quest_id") and i.get("quest_id") != null:
				continue
			else:
				push_warning("Loot Table has entries with their drop types set to quest drops without quest id's set up properly. These items will not drop.")	
				warnings += 1
			if i.has("quest_item_total_count") and i.get("quest_item_total_count") != null:
				continue
			else:
				push_warning("Loot Table has quest entries without quest item total count set properly. This value will be set to 1.")
				warnings += 1
				
		if i.has("DropType") and i.get("DropType") != null:
			continue
		else:
			push_warning("Loot Table has entries without drop type's assigned. These entries will not drop.")	
			warnings += 1
			
		if i.has("weight") and i.get("weight") != null:
			continue
		else:
			push_warning("Loot Table has entries without weights assigned. These entries will not drop.")
			warnings += 1
				
		if i.has("quantity_min") and i.get("quantity_min") != null:
			continue
		else:
			push_warning("Loot Table has chance drop entries without minimum quantities set properly. These values will be set to 1.")	
			warnings += 1
			
		if i.has("quantity_max") and i.get("quantity_max") != null:
			continue
		else:
			push_warning("Loot Table has chance drop entries without maximum quantities set properly. These values will be set to 1.")
			warnings += 1
	
	if errors > 0:
		print("Loot Component has encountered " + str(errors) + " errors. Please fix those before initialization.")
		return false
	else:
		if warnings > 0:
			print("Loot Component has raised " + str(warnings) + " warnings. While these will not affect functionality, fixing is recommended.")
		return true
