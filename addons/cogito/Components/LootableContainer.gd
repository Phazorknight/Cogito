## Handles loot generation within a CogitoContainer. Can be customizable with additional parameters.
class_name LootableContainer extends Node3D

@export_category("Master Control")
## Enables or disables the lootable container's functionality.
@export var enabled = true
## Container this component belongs to and will handle its inventory.
@export var container: CogitoContainer
##
@export var debug_prints: bool = false

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
## Timer node reference to handle respawning.
var timer: Timer
## Boolean to improve the container refresh logic.
var viewing_this_container: bool = false


func _ready() -> void:
	call_deferred("_set_up_references")
	call_deferred("_sort_loot_table")
	call_deferred("_handle_inventory")
	call_deferred("_handle_respawning")
	

func _set_up_references():
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)
	_player_inventory = _player.inventory_data
	_player_interaction_component = _player.player_interaction_component
	
	if container:
		container.add_to_group("lootable_container")
		inventory_to_populate = container.inventory_data
		
	container.toggle_inventory.connect(_on_inventory_toggled)


## Handle Inventory
func _handle_inventory():
	
	var lootgen = LootGenerator.new()
	get_tree().current_scene.add_child(lootgen)
	finalized_items = lootgen.generate(loot_table, amount_of_items_to_drop, true)
	get_tree().current_scene.call_deferred("queue_free", lootgen)
	
	_populate_the_container(inventory_to_populate, finalized_items)


# Calculate the proper value for the timer component
func _calculate_timer_value() -> float:
	var calculated_respawn_timer: float
	calculated_respawn_timer = (respawn_timer_days * 86400.0) + (respawn_timer_hours * 3600.0) + (respawn_timer_minutes * 60.0) + respawn_timer_seconds
	return calculated_respawn_timer


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
		# Close the container before clearing the slots
		if _player_hud != null and viewing_this_container:
			if debug_prints:
				print("Player Hud found and is viewing this container:" + str(container))
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
	if debug_prints:
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
		if debug_prints:
			print("Slot number: " + str(_index) + " holds item: " + str(slots[_index]))
		_index += 1
	# reopen the container to refresh inventory
	if _player_hud != null and viewing_this_container:
		if _player_hud.inventory_interface.is_inventory_open:
			if _player_interaction_component.last_interacted_node.get_parent() == container:
				_player_hud.inventory_interface.set_external_inventory(container)


## Handles the respawning logic for the inventory_respawning_logic enum.
func _handle_respawning():
	match inventory_respawning_logic:
		InventoryRespawningLogic.NONE:
			return
		InventoryRespawningLogic.TIMED_RESPAWN:
			timer = Timer.new()
			add_child(timer)
			timer.wait_time = _calculate_timer_value()
			timer.one_shot = false
			timer.timeout.connect(_handle_inventory)
			timer.start()
			if debug_prints:
				print("Timer created for: " + str(timer.wait_time) + " seconds.")


## Connected to inventory signal to increase container refresh logic accuracy
func _on_inventory_toggled(external_inventory_owner: Node):
	if container == external_inventory_owner:
		if _player_hud != null and _player_hud.inventory_interface.is_inventory_open:
			viewing_this_container = true
		else: 
			viewing_this_container = false

func _exit_tree() -> void:
	if container.toggle_inventory.is_connected(_on_inventory_toggled):
		container.toggle_inventory.disconnect(_on_inventory_toggled)
