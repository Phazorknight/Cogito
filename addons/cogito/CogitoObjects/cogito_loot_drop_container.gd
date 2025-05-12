class_name LootDropContainer extends CogitoContainer


## Enables the debug prints. There are quite a few so output may be crowded.
@onready var debug_prints: bool = CogitoGlobals.cogito_settings.loot_drop_container_debug

## Determine the despawning logic for this container.
@export var despawning_logic := DespawningLogic.NONE:
	set(value):
		despawning_logic = value
		notify_property_list_changed()
## Despawn timer used by the timed despawning function.
@export_range(0, 600, 10, "suffix:seconds") var despawn_timer :float = 60.0
@export var random_despawn_test: bool = false
## Should this container's despawn logic account for the time passed while calculating the despawn timer.
@export var time_passes_when_unloaded: bool = true

## Internal reference to time left variable that is saved and loaded.
var time_left: float = 0.0
## Loaded time_left
var loaded_time_left: float = 0.0
## Initial spawn bool. This only true during first spawn. On loading this value is set to false and remains false.
var initial_spawn = true
## Internal reference to the despawning timer.
var timer: Timer

## Internal reference to start time that is saved and loaded.
var start_time: float
## Internal reference to current time that assigned just in time.
var current_time: float
## Internal reference to end time that is saved and loaded.
var end_time: float

## Mark for deletion
var marked_for_deletion: bool = false

# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager

enum DespawningLogic {
NONE = 0, ## Container will not despawn and will become part of the scene. 
ONLY_EMPTY = 1, ## Container will despawn only after player takes out the last item in it.
ONLY_EMPTY_POST_INTERACTION = 2, ## Container will despawn only after player takes out the last item in it. This option will delay container deletion until player stops interacting with the container. Even if player puts an item in the container, container is deleted upon closing of the external_inventory.
ONLY_TIMED = 4, ## Container will despawn after a preset time interval started upon container creation. Note: Items present will be lost with timed despawning logic.
EMPTY_AND_TIMED = 8 ## Container will despawn after a time period as well as upon a timer expiration. Note: Items present will be lost with timed despawning logic.
}

const DESPAWNINGLOGICTYPES: Array = [DespawningLogic.NONE, DespawningLogic.ONLY_EMPTY, DespawningLogic.ONLY_EMPTY_POST_INTERACTION, DespawningLogic.ONLY_TIMED, DespawningLogic.EMPTY_AND_TIMED]


func _ready() -> void:
	
	if debug_prints:
		despawning_logic = DESPAWNINGLOGICTYPES[randi() % DESPAWNINGLOGICTYPES.size()]
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Debug prints bool is true. Randomizing container despawn types. Despawning Logic is set to: " + str(despawning_logic))
	
	call_deferred("_set_up_references")
	call_deferred("_handle_despawning")
	
	add_to_group("external_inventory")
	add_to_group("loot_bag")
	add_to_group("interactable")
	add_to_group("Persist")

	interaction_nodes = find_children("","InteractionComponent",true)
	interaction_text = text_when_closed
	object_state_updated.emit(interaction_text)
	inventory_data.apply_initial_inventory()


## Set up references to player and container in a deferred manner to avoid nulling
func _set_up_references():
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)

	# Connects to hud signal to be able to interact with this spawned object.
	if !self.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
			self.toggle_inventory.connect(_player_hud.toggle_inventory_interface)
	

## Handles the despawning logic for the despawning_logic enum.
func _handle_despawning():
	match despawning_logic:
		DespawningLogic.NONE: # this container is a part of the scene now permanently.
			return
			
		DespawningLogic.ONLY_EMPTY:
			if !self.inventory_data.inventory_updated.is_connected(_on_inventory_updated):
				self.inventory_data.inventory_updated.connect(_on_inventory_updated)
			
			if !self._player_hud.hide_inventory.is_connected(_on_inventory_hidden):
				self._player_hud.hide_inventory.connect(_on_inventory_hidden)
				
		DespawningLogic.ONLY_EMPTY_POST_INTERACTION:
			if !self.inventory_data.inventory_updated.is_connected(_on_inventory_updated):
				self.inventory_data.inventory_updated.connect(_on_inventory_updated)
				
			if !self.toggle_inventory.is_connected(_on_inventory_toggled):
				self.toggle_inventory.connect(_on_inventory_toggled)
				
			if !self._player_hud.hide_inventory.is_connected(_on_inventory_hidden):
				self._player_hud.hide_inventory.connect(_on_inventory_hidden)
			
		DespawningLogic.ONLY_TIMED:
			if !self.toggle_inventory.is_connected(_on_inventory_toggled):
				self.toggle_inventory.connect(_on_inventory_toggled)
				
			if !self._player_hud.hide_inventory.is_connected(_on_inventory_hidden):
				self._player_hud.hide_inventory.connect(_on_inventory_hidden)

			if timer == null:
				_set_up_timer()
			
		DespawningLogic.EMPTY_AND_TIMED:
			if !self.inventory_data.inventory_updated.is_connected(_on_inventory_updated):
				self.inventory_data.inventory_updated.connect(_on_inventory_updated)
		
			if !self.toggle_inventory.is_connected(_on_inventory_toggled):
				self.toggle_inventory.connect(_on_inventory_toggled)
				
			if !self._player_hud.hide_inventory.is_connected(_on_inventory_hidden):
				self._player_hud.hide_inventory.connect(_on_inventory_hidden)
			
			if timer == null:
				_set_up_timer()


## Set up a timer in deferred manner
func _set_up_timer():
	if timer == null:
		timer = Timer.new()
		
		if initial_spawn:
			start_time = Time.get_unix_time_from_system()
			end_time = Time.get_unix_time_from_system() + despawn_timer
		
		add_child(timer)
		timer.one_shot = true
		timer.wait_time = _calculate_wait_time()
		timer.timeout.connect(_on_despawn_timer_timeout)
		
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Initial Spawn: " + str(initial_spawn) + "Timer State: " + str(timer.is_stopped()))
		
		timer.start()
		
		initial_spawn = false

		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "timer NOT found and time left set is: " + str(timer.wait_time) + " | Timer state: " + str(timer.is_stopped()))

	else:
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "set_up_timer was ran but timer already existed during call with these settings: ")
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Timer ID: " + str(timer))
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Timer One Shot?: " + str(timer.one_shot))
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Timer Wait Time: " + str(timer.wait_time))
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Timer Start Time: " + str(start_time) )
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Timer End Time: " + str(end_time))


## Calculate the wait time of the timer
func _calculate_wait_time() -> float:
	var _time: float
	if timer != null:
		if !initial_spawn :
			if time_passes_when_unloaded:
				current_time = Time.get_unix_time_from_system()
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "timer is: " + str(timer))
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Start Time is: " + str(start_time))
					
				if current_time < end_time:
					_time = end_time - current_time
					CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Current time is smaller than end time. _time is set to: " + str(_time))
					
				elif current_time > end_time:
					_time = 3.0
					CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Allotted time for existence has passed. Setting _time to 3.0 to initiate despawn.")
			else:
				if time_left > 0.0:
					_time = time_left
		elif initial_spawn: # default wait time script does not set wait time to 1.0 explicity so magic numbering this should work in theory.
			_time = despawn_timer
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
	#if time_accumulator >= 1.0 and debug_prints and timer != null:
		#CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Timer.time_left: " + str(timer.time_left) + " Time_left: " + str(time_left) + " Timer.wait_time: " + str(timer.wait_time) + " end_time: " + str(end_time))
		#time_accumulator = 0.0
#endregion


## Timer calls this function to despawn the container and all within it.
func _on_despawn_timer_timeout():
	if _clear_for_despawning():
		if _player_hud != null:
			if _player_hud.inventory_interface.is_inventory_open:
				if _player_hud.inventory_interface.get_external_inventory() == self:
					_player_hud.inventory_interface.clear_external_inventory()
		
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Despawning Container: " + str(self))
		_remove_container()
	else:
		CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Container: " + str(self) + " is unable to despawn.")
		return


## On inventory updated signal emitted, do the slot checks and if all slots are empty, remove the container from world.
func _on_inventory_updated(inventory_data : CogitoInventory):
	var inventory_slot_data = self.inventory_data.inventory_slots
	var items_in_slots: Array[InventoryItemPD] = []
	
	if inventory_slot_data != null:
		for _slots in inventory_slot_data:
			if _slots != null:
				if _slots.inventory_item != null:
					items_in_slots.append(_slots.inventory_item)
					
		if items_in_slots.is_empty():
			if despawning_logic == DespawningLogic.ONLY_EMPTY:
				if _player_hud != null:
					if _player_hud.inventory_interface.is_inventory_open:
						if _player_hud.inventory_interface.get_external_inventory() == self:
							_player_hud.toggle_inventory_interface(self)
							
				_remove_container()
				
			elif despawning_logic == DespawningLogic.ONLY_EMPTY_POST_INTERACTION or despawning_logic == DespawningLogic.EMPTY_AND_TIMED:
				marked_for_deletion = true
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Container is now marked for deletion. Will process after inventory closed.")
				


## Removal of the container
func _remove_container():
	if self.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
		self.toggle_inventory.disconnect(_player_hud.toggle_inventory_interface)
				
	if self.toggle_inventory.is_connected(_on_inventory_toggled):
		self.toggle_inventory.disconnect(_on_inventory_toggled)

	if self.inventory_data.inventory_updated.is_connected(_on_inventory_updated):
		self.inventory_data.inventory_updated.disconnect(_on_inventory_updated)
		
	if self._player_hud.hide_inventory.is_connected(_on_inventory_hidden):
		self._player_hud.hide_inventory.disconnect(_on_inventory_hidden)
		
	call_deferred("queue_free")


## Handle the ESC and TAB keys.
func _on_inventory_hidden():
	if !despawning_logic == DespawningLogic.NONE:
		if marked_for_deletion:
			CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Despawning marked container: " + str(self))
			_remove_container()
			
		if despawning_logic == DespawningLogic.ONLY_TIMED or despawning_logic == DespawningLogic.EMPTY_AND_TIMED:
			if timer != null and timer.paused:
				_unpause_timer()
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Paused timer of: " + str(self) + " was unpaused.")


## Pause the timer on inventory access
func _on_inventory_toggled(external_inventory_owner: Node):
	if self == external_inventory_owner:
		if _player_hud.inventory_interface.is_inventory_open:
			if timer != null:
				_pause_timer()
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Pausing timer. Time Remaining: " + str(timer.time_left) + " " + str(time_left)+ " " + str(timer.wait_time))
				
		else:
			if timer != null:
				_unpause_timer()
				CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Unpausing timer. Time Remaining: " + str(timer.time_left) + " " + str(time_left)+ " " + str(timer.wait_time))


## Check that we aren't actually the scene root. That would be bad.
func _clear_for_despawning() -> bool:
	if is_inside_tree() and get_parent() == null and get_tree().current_scene == self:
		return false
	elif is_inside_tree() and get_parent() != null and get_tree().current_scene != self:
		return true
		
	return false


# Load the saved properties.
func set_state():

	interaction_text = text_when_closed
	animation_player = $AnimationPlayer
	initial_spawn = false
	
	if despawning_logic == DespawningLogic.ONLY_TIMED or despawning_logic == DespawningLogic.EMPTY_AND_TIMED:
	
		if timer == null:
			_set_up_timer()
		
	object_state_updated.emit(interaction_text)


# Custom save function to keep a few more properties.
func save():
	if timer != null:
		if timer.time_left > 0:
			time_left = timer.time_left
			CogitoGlobals.debug_log(debug_prints, "Loot Component/Loot Drop Container", "Time left before despawning: " + str(time_left))

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
		"initial_spawn" : initial_spawn,
	}
	return node_data
	
