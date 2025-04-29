class_name LootableContainerX extends CogitoContainer

## Enable debug information being dumped straight into the output window.
@export var debug_prints: bool = true
## Determine the despawning logic for this container.
@export_category("Execution Configuration")

@export_category("Loot Table Configuration")
## Specifies which loot table should be used to spawn items from.
@export var loot_table: LootTable
## Variable that determines how many items will be dropped from the chance and quest items specified in the loot table. Chance and quest drop items will be joined and rolled this many times. Guaranteed items do not count towards this limit and will always drop regardless. Note that you can run out of screen space in containers if you add more than 64 items total.
@export var amount_of_items_to_drop: int = 1

## Handles the respawning logic for inventory of CogitoContainer.
@export var inventory_respawning_logic := InventoryRespawningLogic.NONE:
	set(value):
		inventory_respawning_logic = value
		notify_property_list_changed()
## Respawn timer is calculated based on the values below. With all values converted to seconds and added together to generate a final timer.
## Should time passed while this container is unloaded accounted for inventory respawn?
@export var time_passes_when_unloaded: bool = true
@export_group("Respawn Timer")
## Respawn timer days component. Will be added as days 86400 seconds to final timer calculation.
@export_range(0, 30, 1, "suffix:days") var respawn_timer_days :float = 0.0
## Respawn timer used by the timed respawning function.
@export_range(0, 24, 1, "suffix:hours") var respawn_timer_hours :float = 0.0
## Respawn timer used by the timed respawning function.
@export_range(0, 60, 1, "suffix:minutes") var respawn_timer_minutes :float = 1.0
## Respawn timer used by the timed respawning function.
@export_range(0, 60, 1, "suffix:seconds") var respawn_timer_seconds :float = 0.0


## Boolean to improve the container refresh logic.
var viewing_this_container: bool = false
## Contains the finalized array which will be sent to roll items.
var finalized_items: Array[Dictionary]
## CogitoContainer's inventory component.
var inventory_to_populate:CogitoInventory
## Respawn timer calculated value.
var calculated_respawn_timer: float

## Internal reference to the despawning timer.
var timer: Timer
## Internal reference to time left variable that is saved and loaded.
var time_left: float = 0.0
## Internal reference to start time that is saved and loaded.
var start_time: float
## Internal reference to current time that assigned just in time.
var current_time: float
## Internal reference to end time that is saved and loaded.
var end_time: float


# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager
var _player_inventory: CogitoInventory
var _player_interaction_component: PlayerInteractionComponent

enum InventoryRespawningLogic {
NONE, ## Contents of the container will not respawn. It will be safe for player to put his items in and out after the initialization.
TIMED_RESPAWN, ## Contents of the container will respawn upon the expiration of the timer. This will reset the inventory and reroll new items from the loot table provided.
}

func _ready() -> void:
	super._ready() # call the parent class' _ready function before doing our own thing.
	add_to_group("Persist")
	add_to_group("lootable_container")
	
	call_deferred("_set_up_references")
	call_deferred("_handle_inventory")
	call_deferred("_handle_respawning")


## Set up references to player and container in a deferred manner to avoid nulling
func _set_up_references():
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)
	_player_inventory = _player.inventory_data
	_player_interaction_component = _player.player_interaction_component
	
	if self.inventory_data != null:
		inventory_to_populate = self.inventory_data
	else:
		return
	
	
## Calculate the proper value for the timer component
func _calculate_timer_value():
	calculated_respawn_timer = ((respawn_timer_days * 86400.0) + (respawn_timer_hours * 3600.0) + (respawn_timer_minutes * 60.0) + respawn_timer_seconds)
	
	if debug_prints:
		print("Calculated respawn timer is: " + str(calculated_respawn_timer))
	
	
## Handle Inventory
func _handle_inventory():
	
	var lootgen = LootGenerator.new()
	get_tree().current_scene.add_child(lootgen)
	finalized_items = lootgen.generate(loot_table, amount_of_items_to_drop, true)
	lootgen.call_deferred("queue_free")
	
	_populate_the_container(inventory_to_populate, finalized_items)
	
	
## Handles the respawning logic.
func _handle_respawning():
	match inventory_respawning_logic:
		InventoryRespawningLogic.NONE:
			return
		InventoryRespawningLogic.TIMED_RESPAWN:
			if !self.toggle_inventory.is_connected(_on_inventory_toggled):
				self.toggle_inventory.connect(_on_inventory_toggled)
			
			if timer == null:
				_calculate_timer_value()
				_create_timer()
				
			timer.timeout.connect(_handle_inventory)
			_start_timer()
		
			
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
				print("Player Hud found and is viewing this container:" + str(self))
			if _player_hud.inventory_interface.is_inventory_open:
				if _player_hud.inventory_interface.get_external_inventory() == self:
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
			if _player_interaction_component.last_interacted_node.get_parent() == self:
				_player_hud.inventory_interface.set_external_inventory(self)

## Set up a timer in deferred manner
func _create_timer():
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = false
	timer.wait_time = calculated_respawn_timer
	
	if debug_prints:
		print("Timer initialized as: " + str(timer.wait_time))


func _start_timer():
	if timer != null:
		timer.one_shot = true
		
		if time_left > 0: # this variable is only 0 during initial spawn.
			timer.wait_time = time_left
			
		else: # what to do during initial spawn
			
			start_time = Time.get_unix_time_from_system()
			end_time = start_time + calculated_respawn_timer
			timer.wait_time = calculated_respawn_timer
			time_left = timer.wait_time
			
			if debug_prints:
				print("Start time is : " + str(start_time))
				print("End Time is: " + str(end_time))
				
		timer.start()
		
		if debug_prints:
			print("Starting timer. Time Remaining on timer.time_left: " + str(timer.time_left) + " Time Remaining on time_left: " + str(time_left) + " timer.wait_time: " + str(timer.wait_time))


func _pause_timer():
	if timer != null:
		timer.paused = true

func _unpause_timer():
	if timer != null:
		timer.paused = false


## Pause the timer on inventory access
func _on_inventory_toggled(external_inventory_owner: Node):
	if self == external_inventory_owner:
		if _player_hud.inventory_interface.is_inventory_open:
			_pause_timer()
			viewing_this_container = true
			if debug_prints:
				print("Pausing timer. Time Remaining: " + str(timer.time_left))
				
		else:
			_unpause_timer()
			viewing_this_container = false
			if debug_prints:
				print("Unpausing timer. Time Remaining: " + str(timer.time_left))


# Load the saved properties.
func set_state():
	interaction_text = text_when_closed
	animation_player = $AnimationPlayer
	
	if inventory_respawning_logic == InventoryRespawningLogic.TIMED_RESPAWN:
		print("top kek")
		if time_left > 0:
			if timer != null:
				start_time = end_time - calculated_respawn_timer
				
				if debug_prints:
					print("timer is: " + str(timer))
					print("Restored Start Time is: " + str(start_time))
					
				if !time_passes_when_unloaded:
					timer.wait_time = time_left # time does NOT progress when unloaded
					
					if debug_prints:
						print("Loaded time_left variable: " + str(time_left))
						
				else:
					current_time = Time.get_unix_time_from_system()
					var final_wait_time: float = end_time - current_time
					
					if final_wait_time > 0:
						timer.wait_time = end_time - current_time # time does progress when unloaded
						if debug_prints:
							print("Final timer.wait_time variable: " + str(timer.wait_time))
					else:
						_handle_inventory()
						if debug_prints:
							print("Allotted time for existence has passed. Proceeding to inventory respawning.")
		else:
			_handle_inventory()
	elif inventory_respawning_logic == InventoryRespawningLogic.NONE:
		print("top lol")
	
	object_state_updated.emit(interaction_text)


# Custom save function to keep a few more properties.
func save():
	if inventory_respawning_logic == InventoryRespawningLogic.TIMED_RESPAWN:
		current_time = Time.get_unix_time_from_system()
		var remaining_time = end_time - current_time
		
		if remaining_time > 0:
			time_left = remaining_time
			
			if debug_prints:
				print("Time left before despawning: " + str(remaining_time))
		else:
			time_left = 0.0
		
		var node_data = {
			"filename" : get_scene_file_path(),
			"parent" : get_parent().get_path(),
			"node_path" : self.get_path(),
			"display_name" : display_name,
			"inventory_data" : inventory_data,
			"interaction_nodes" : interaction_nodes,
			"animation_player" : animation_player,
			"pos_x" : position.x,
			"pos_y" : position.y,
			"pos_z" : position.z,
			"rot_x" : rotation.x,
			"rot_y" : rotation.y,
			"rot_z" : rotation.z,
			"start_time" : start_time,
			"end_time" : end_time,
			"time_left" : time_left,
			
		}
		return node_data
	elif inventory_respawning_logic == InventoryRespawningLogic.NONE:
		print("Just an ordinary save node_data")
		var node_data = {
			"filename" : get_scene_file_path(),
			"parent" : get_parent().get_path(),
			"node_path" : self.get_path(),
			"display_name" : display_name,
			"inventory_data" : inventory_data,
			"interaction_nodes" : interaction_nodes,
			"animation_player" : animation_player,
			"pos_x" : position.x,
			"pos_y" : position.y,
			"pos_z" : position.z,
			"rot_x" : rotation.x,
			"rot_y" : rotation.y,
			"rot_z" : rotation.z,
			
		}
		return node_data
