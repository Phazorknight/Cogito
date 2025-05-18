## Generates a bag of loot after death. This inventory is not a grid inventory, each dropped item will have its own slot.
class_name LootComponent extends Node3D 


## Enables the debug prints. There are quite a few so output may be crowded.
@onready var debug_prints: bool = CogitoGlobals.cogito_settings.loot_component_debug

@export_category("Master Control")
## Enables or disables the loot components functionality.
@export var enabled = true
## Determine the spawning logic for this container.
@export var spawning_logic := SpawningLogic.NONE:
	set(value):
		spawning_logic = value
		notify_property_list_changed()
@export var percentage_of_chance_to_spawn: float = 100.0

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

# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager
var _player_inventory: CogitoInventory

enum SpawningLogic {
NONE = 0, ## Default spawning logic, will not actually spawn anything even if component is enabled.
SPAWN_ITEM = 1, ## Spawns an item defined in the InventoryItemPD's drop_scene variable instead of a container. 
SPAWN_CONTAINER = 2, ## Spawns a loot drop container to fill up with rolled items. 
}

func _get_configuration_warnings():
	if !loot_table:
		return ["Loot table is not set. It is required for the loot component to function."]


func _ready() -> void:
	call_deferred("_set_up_references")


## Set up references to player in a deferred manner to avoid nulling during tree operation
func _set_up_references():
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)
	_player_inventory = _player.inventory_data
	
	if spawning_logic == SpawningLogic.SPAWN_ITEM:
		health_component_to_monitor.death.connect(_spawn_loot)
	elif spawning_logic == SpawningLogic.SPAWN_CONTAINER:
		health_component_to_monitor.death.connect(_spawn_loot_container)
	else:
		CogitoGlobals.debug_log(debug_prints, "Loot Component", "Spawning Logic for this loot component is set to None. Component will not function. Parent: " + str(get_parent()))


## Spawns the loot rolled by the loot generator. 
func _spawn_loot():
	## Parent node's global position
	var parent_position = get_parent().global_position
	## The array of rolled items from which we will get the drop_scene variables from.
	var items_to_spawn: Array[LootDropEntry] = []
	## CogitoObject references of spawned items to rename the display name.
	var spawned_items: Array[CogitoObject] = []
	
	if enabled and amount_of_items_to_drop > 0:
		var lootgen = LootGenerator.new()
		get_tree().current_scene.add_child(lootgen)
		items_to_spawn = lootgen.generate(loot_table, amount_of_items_to_drop)
		lootgen.call_deferred("queue_free")
		
		for item in items_to_spawn:
			if item.inventory_item.drop_scene != null:
				var item_to_spawn = load(item.inventory_item.drop_scene)
				var spawned_item = item_to_spawn.instantiate() as CogitoObject
				spawned_item.position = parent_position
				get_tree().current_scene.add_child(spawned_item)
				
				var children: Array = []
				children = spawned_item.get_children()
				
				# Sort through children to find the pickup components.
				if children.size() > 0:
					for child in children:
						if child is PickupComponent:
							child.slot_data.quantity = randi_range(item.quantity_min, item.quantity_max) # adjust quantity based on the loot table data.
				
				var impulse = Vector3(randf_range(0,3),5,randf_range(0,3))
				spawned_item.call_deferred("apply_central_impulse", impulse)
				spawned_items.append(spawned_item)
				spawned_item.add_to_group("spawned_loot_items")
		
		for item in spawned_items:
			var children: Array = []
			children = item.get_children()
			
			if children.size() > 0:
				for child in children:
					# adjust name to reflect quantity in the dropped item.
					if child is PickupComponent:
						if child.slot_data.inventory_item.name != null and child.slot_data.quantity > 1:
							item.display_name = str(child.slot_data.inventory_item.name + " x" + str(child.slot_data.quantity))
						elif child.slot_data.quantity == 1:
							item.display_name = str(child.slot_data.inventory_item.name) # This really should be set in the resource itself but for testing purposes this is fine.


## Spawns the loot container defined in the loot_bag_scene variable.
func _spawn_loot_container():
	## Parent node's global position
	var parent_position = get_parent().global_position
	## Loot bag scene that is instantiated during runtime.
	var spawned_loot_bag
	## Spawned loot bag's inventory component.
	var inventory_to_populate:CogitoInventory
	## Contains the finalized array which will be sent to roll items.
	var finalized_items: Array[LootDropEntry]
	## Array to merge chance and quest drops in.
	var merged_array: Array[Dictionary]
	
	if enabled and amount_of_items_to_drop > 0:
		spawned_loot_bag = loot_bag_scene.instantiate()
		spawned_loot_bag.position = parent_position
		get_tree().current_scene.call_deferred("add_child", spawned_loot_bag)
		
		if !spawned_loot_bag.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
			spawned_loot_bag.toggle_inventory.connect(_player_hud.toggle_inventory_interface)

		inventory_to_populate = spawned_loot_bag.inventory_data
		inventory_to_populate.resource_local_to_scene = true

		spawned_loot_bag.add_to_group("loot_bag")
		spawned_loot_bag.add_to_group("Persist")
		CogitoGlobals.debug_log(debug_prints, "Loot Component", "Spawned Loot Bag: " + str(spawned_loot_bag) + "at these coordinates: " + str(spawned_loot_bag.position))
		
		var lootgen = LootGenerator.new()
		get_tree().current_scene.add_child(lootgen)
		finalized_items = lootgen.generate(loot_table, amount_of_items_to_drop)
		lootgen.call_deferred("queue_free")
		
		_populate_the_container(inventory_to_populate, finalized_items)


## Populates the spawned container with the rolled items.
func _populate_the_container(_inventory: CogitoInventory, _items: Array[LootDropEntry]):
	## Index value that is iterated independently of the for loops it is used inside.
	var _index :int =  0
	## Dictionary array's size which is passed to the function during call.
	var _item_count: int = _items.size()
	## InventorySlotPD count of the inventory that is passed during function call.
	var slots: Array[InventorySlotPD] = _inventory.inventory_slots

	slots.resize(_item_count)
	_inventory.inventory_size.x = 8
	_inventory.inventory_size.y = _item_count / 8 + 1
	if _item_count:
		_inventory.first_slot = slots[0]
	CogitoGlobals.debug_log(debug_prints, "Loot Component", "Inventory size set to: " + str(slots.size()))
	
	for i in _item_count:
		slots[i] = InventorySlotPD.new()
		
	for item in _items:
		slots[_index].inventory_item = item.inventory_item
		slots[_index].set_quantity(randi_range(item.quantity_min, item.quantity_max))
		slots[_index].origin_index = _index
		slots[_index].resource_local_to_scene = true
		slots[_index].inventory_item.resource_local_to_scene = true
		_index += 1
	
	_index = 0
	
	if debug_prints:
		for i in slots:
			CogitoGlobals.debug_log(debug_prints, "Loot Component", "Slot number: " + str(_index) + " holds item: " + str(slots[_index]))
			_index += 1
