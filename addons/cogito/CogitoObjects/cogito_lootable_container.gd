class_name LootableContainer extends CogitoContainer

## Enables the debug prints. There are quite a few so output may be crowded.
@onready var debug_prints: bool = CogitoGlobals.cogito_settings.lootable_container_debug

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
var finalized_items: Array[LootDropEntry]
## CogitoContainer's inventory component.
var inventory_to_populate:CogitoInventory
## Respawn timer calculated value.
var calculated_respawn_timer: float
## Initial spawn bool. This only true during first spawn. On loading this value is set to false and remains false.
var initial_spawn = true

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
	
	add_to_group("save_object_state")
	add_to_group("lootable_container")
	add_to_group("external_inventory")
	add_to_group("interactable")
	
	call_deferred("_set_up_references")
	call_deferred("_handle_inventory")
	call_deferred("_handle_respawning")
	
	interaction_nodes = find_children("","InteractionComponent",true)
	interaction_text = text_when_closed
	object_state_updated.emit(interaction_text)
	inventory_data.apply_initial_inventory()


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
	
	CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Calculated respawn timer is: " + str(calculated_respawn_timer))
	
	
## Handle Inventory
func _handle_inventory():
	
	var lootgen = LootGenerator.new()
	get_tree().current_scene.add_child(lootgen)
	finalized_items = lootgen.generate(loot_table, amount_of_items_to_drop)
	lootgen.call_deferred("queue_free")
	
	_populate_the_container(inventory_to_populate, finalized_items)


## Respawn
func _respawn():
	if !timer.is_stopped():
		timer.stop()
	
	_calculate_timer_value()
	end_time = Time.get_unix_time_from_system() + calculated_respawn_timer	
	timer.wait_time = calculated_respawn_timer
	_handle_inventory()
	timer.start()


## Handles the respawning logic.
func _handle_respawning():
	match inventory_respawning_logic:
		InventoryRespawningLogic.NONE:
			return
		InventoryRespawningLogic.TIMED_RESPAWN:
			if !self.toggle_inventory.is_connected(_on_inventory_toggled):
				self.toggle_inventory.connect(_on_inventory_toggled)
				
			if !self._player_hud.hide_inventory.is_connected(_on_inventory_hidden):
				self._player_hud.hide_inventory.connect(_on_inventory_hidden)
			
			if timer == null:
				_calculate_timer_value()
				_set_up_timer()


## Populates the spawned container with the rolled items.
func _populate_the_container(_inventory: CogitoInventory, _items: Array[LootDropEntry]):
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
			CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Player Hud found and is viewing this container:" + str(self))
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
	CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Inventory size set to: " + str(slots.size()))
	for i in _item_count:
		slots[i] = InventorySlotPD.new()
		
	for item in _items:
		slots[_index].inventory_item = item.inventory_item
		slots[_index].set_quantity(randi_range(item.quantity_min, item.quantity_max) )
		slots[_index].origin_index = _index
		slots[_index].resource_local_to_scene = true
		slots[_index].inventory_item.resource_local_to_scene = true
		_index += 1
	
	_index = 0
	for i in slots:
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Slot number: " + str(_index) + " holds item: " + str(slots[_index]))
		_index += 1
	# Reopen the container to refresh inventory displayed in the external_inventory. However currently interacting with the lootable container pauses respawn timer, this is kept as a further option but the way it is set up, cannot actually refresh.
	if _player_hud != null and viewing_this_container:
		if _player_hud.inventory_interface.is_inventory_open:
			_player_hud.inventory_interface.set_external_inventory(self)


## Set up timer
func _set_up_timer():
	if timer == null:
		timer = Timer.new()
	
		if initial_spawn:
			start_time = Time.get_unix_time_from_system()
			end_time = Time.get_unix_time_from_system() + calculated_respawn_timer
		
		add_child(timer)
		timer.one_shot = false
		timer.wait_time = _calculate_wait_time()
		timer.timeout.connect(_respawn)
		
		timer.start()
		initial_spawn = false
	
	else:
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "set_up_timer was ran but timer already existed during call with these settings: ")
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Timer ID: " + str(timer))
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Timer One Shot?: " + str(timer.one_shot))
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Timer Wait Time: " + str(timer.wait_time))
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Timer Start Time: " + str(start_time) )
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Timer End Time: " + str(end_time))

func _calculate_wait_time() -> float:
	var _time: float
	if timer != null:
		if !initial_spawn :
			if time_passes_when_unloaded:
				current_time = Time.get_unix_time_from_system()
				
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "timer is: " + str(timer))
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Start Time is: " + str(start_time))
					
				if current_time < end_time:
					_time = end_time - current_time
					CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Current time is smaller than end time. _time is set to: " + str(_time))
					
				elif current_time > end_time:
					_time = 3.0
					CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Allotted time for existence has passed. Setting _time to 3.0 to initiate respawn.")
			else:
				if time_left > 0.0:
					_time = time_left
		elif initial_spawn: # default wait time script does not set wait time to 1.0 explicity so magic numbering this should work in theory.
			_time = calculated_respawn_timer
	return _time


## Simply pauses the timer.
func _pause_timer():
	if timer != null:
		timer.paused = true


## Unpauses the timer and adjusts the end_time to reflect the paused time.
func _unpause_timer():
	if timer != null:
		timer.paused = false
		end_time = Time.get_unix_time_from_system() + timer.time_left


#region timer debugging, uncomment if you are unsure if the timers' times are correctly counting down - will spam the log every second.
#var time_accumulator = 0.0
#func _process(delta):
	#time_accumulator += delta
	#if time_accumulator >= 1.0 and debug_prints and inventory_respawning_logic == InventoryRespawningLogic.TIMED_RESPAWN:
		#CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Timer.time_left: " + str(timer.time_left) + " Time_left: " + str(time_left) + " Timer.wait_time: " + str(timer.wait_time) + " end_time: " + str(end_time))
		#time_accumulator = 0.0
#endregion


## If inventory was hidden clear the variable so we don't pop up again unintentionally. Also unpause the timer because TAB and ESC keys won't be handled otherwise.
func _on_inventory_hidden():
	if viewing_this_container:
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Inventory Hidden signal receieved. Clearing viewing_this_container variable.")
		if viewing_this_container:
			viewing_this_container = false
		if inventory_respawning_logic == InventoryRespawningLogic.TIMED_RESPAWN and timer != null:
			_unpause_timer()


## Pause the timer on inventory access
func _on_inventory_toggled(external_inventory_owner: Node):
	if self == external_inventory_owner and inventory_respawning_logic == InventoryRespawningLogic.TIMED_RESPAWN:
		if _player_hud.inventory_interface.is_inventory_open:
			_pause_timer()
			viewing_this_container = true
			CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Pausing timer. Time Remaining: " + str(timer.time_left))
				
		else:
			_unpause_timer()
			viewing_this_container = false
			CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Unpausing timer. Time Remaining: " + str(timer.time_left))


# Load the saved properties.
func set_state():
	interaction_text = text_when_closed
	animation_player = $AnimationPlayer
	initial_spawn = false
	
	if inventory_respawning_logic == InventoryRespawningLogic.TIMED_RESPAWN:
		if timer == null:
			_set_up_timer()
			
	object_state_updated.emit(interaction_text)


# Custom save function to keep a few more properties.
func save():
	if timer != null:
		if timer.time_left > 0:
			time_left = timer.time_left
			CogitoGlobals.debug_log(debug_prints, "Loot Component/Lootable Container", "Time left before despawning: " + str(time_left))
		
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
		"initial_spawn" : initial_spawn
			
		}
	return node_data

func _exit_tree() -> void:
	if self.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
		self.toggle_inventory.disconnect(_player_hud.toggle_inventory_interface)
		
	if self.toggle_inventory.is_connected(_on_inventory_toggled):
		self.toggle_inventory.disconnect(_on_inventory_toggled)
		
	if self._player_hud.hide_inventory.is_connected(_on_inventory_hidden):
		self._player_hud.hide_inventory.disconnect(_on_inventory_hidden)
