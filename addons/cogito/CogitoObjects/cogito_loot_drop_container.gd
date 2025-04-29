class_name LootDropContainer extends CogitoContainer

## Enable debug information being dumped straight into the output window.
@export var debug_prints: bool = true
## Determine the despawning logic for this container.
@export var despawning_logic := DespawningLogic.NONE:
	set(value):
		despawning_logic = value
		notify_property_list_changed()
## Despawn timer used by the timed despawning function.
@export_range(0, 600, 10, "suffix:seconds") var despawn_timer :float = 60.0
## Should this container's despawn logic account for the time passed while calculating the despawn timer.
@export var time_passes_when_unloaded: bool = true
## Internal reference to the despawning timer.
@onready var timer: Timer = $Timer

## Internal reference to time left variable that is saved and loaded.
var time_left: float = 0.0
## Loaded time_left
var loaded_time_left: float = 0.0

## Internal reference to start time that is saved and loaded.
var start_time: float
## Internal reference to current time that assigned just in time.
var current_time: float
## Internal reference to end time that is saved and loaded.
var end_time: float

# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager

enum DespawningLogic {
NONE, ## Container will not despawn and will become part of the scene. 
ONLY_EMPTY, ## Container will despawn only after player takes out the last item in it.
ONLY_TIMED, ## Container will despawn after a preset time interval started upon container creation. Note: Items present will be lost with timed despawning logic.
EMPTY_AND_TIMED ## Container will despawn after a time period as well as upon a timer expiration. Note: Items present will be lost with timed despawning logic.
}

func _ready() -> void:
	#super._ready() # call the parent class' _ready function before doing our own thing.

	call_deferred("_set_up_timer")
	call_deferred("_set_up_references")
	call_deferred("_handle_despawning")
	
	add_to_group("external_inventory")
	add_to_group("interactable")

	interaction_nodes = find_children("","InteractionComponent",true)
	interaction_text = text_when_closed
	object_state_updated.emit(interaction_text)
	inventory_data.apply_initial_inventory()
	
#func set_up():
	#_set_up_references()
	#_set_up_timer()
	#_handle_despawning()

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
			
		DespawningLogic.ONLY_TIMED:
			if !self.toggle_inventory.is_connected(_on_inventory_toggled):
				self.toggle_inventory.connect(_on_inventory_toggled)

			if timer != null:
				timer.timeout.connect(_on_despawn_timer_timeout)
				_start_timer()
			
		DespawningLogic.EMPTY_AND_TIMED:
			if !self.inventory_data.inventory_updated.is_connected(_on_inventory_updated):
				self.inventory_data.inventory_updated.connect(_on_inventory_updated)
		
			if !self.toggle_inventory.is_connected(_on_inventory_toggled):
				self.toggle_inventory.connect(_on_inventory_toggled)

			timer.timeout.connect(_on_despawn_timer_timeout)
			_start_timer()

## Set up a timer in deferred manner
func _set_up_timer():
	if timer == null:
		timer = Timer.new()
		print("timer NOT found and time left set is: " + str(timer.wait_time))
	add_child(timer)
	timer.one_shot = true
	if time_left > 0:
		timer.wait_time = loaded_time_left
	else:
		timer.wait_time = despawn_timer
		print("timer found and time left set is: " + str(timer.wait_time))
	
	if debug_prints:
		print("Timer initialized as: " + str(timer.wait_time))

func _start_timer():
	if timer != null:
		timer.one_shot = true
		
		if time_left > 0: # this variable is only 0 during initial spawn.
			timer.wait_time = time_left
			
		else: # what to do during initial spawn
			
			start_time = Time.get_unix_time_from_system()
			end_time = start_time + despawn_timer
			timer.wait_time = despawn_timer
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
		
var time_accumulator = 0.0
func _process(delta):
	time_accumulator += delta
	if time_accumulator >= 1.0:
		print("Timer.time_left: " + str(timer.time_left) + " Time_left: " + str(time_left) + " Timer.wait_time: " + str(timer.wait_time))
		time_accumulator = 0.0

func _on_despawn_timer_timeout():
	if _clear_for_despawning():
		if _player_hud != null:
			if _player_hud.inventory_interface.is_inventory_open:
				if _player_hud.inventory_interface.get_external_inventory() == self:
					_player_hud.inventory_interface.clear_external_inventory()

		if self.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
			self.toggle_inventory.disconnect(_player_hud.toggle_inventory_interface)
			
		if self.toggle_inventory.is_connected(_on_inventory_toggled):
			self.toggle_inventory.disconnect(_on_inventory_toggled)

		if self.inventory_data.inventory_updated.is_connected(_on_inventory_updated):
			self.inventory_data.inventory_updated.disconnect(_on_inventory_updated)
		
		if debug_prints:
			print("despawning")
		call_deferred("queue_free")
	else:
		if debug_prints:
			print("unable to despawn")
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
			if _player_hud != null:
				if _player_hud.inventory_interface.is_inventory_open:
					if _player_hud.inventory_interface.get_external_inventory() == self:
						_player_hud.inventory_interface.clear_external_inventory()
				
			if self.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
				self.toggle_inventory.disconnect(_player_hud.toggle_inventory_interface)
			
			if self.toggle_inventory.is_connected(_on_inventory_toggled):
				self.toggle_inventory.disconnect(_on_inventory_toggled)

			if self.inventory_data.inventory_updated.is_connected(_on_inventory_updated):
				self.inventory_data.inventory_updated.disconnect(_on_inventory_updated)
			
			call_deferred("queue_free")


## Pause the timer on inventory access
func _on_inventory_toggled(external_inventory_owner: Node):
	if self == external_inventory_owner:
		if _player_hud.inventory_interface.is_inventory_open:
			_pause_timer()
			if debug_prints:
				print("Pausing timer. Time Remaining: " + str(timer.time_left) + " " + str(time_left)+ " " + str(timer.wait_time))
				
		else:
			_unpause_timer()
			if debug_prints:
				print("Unpausing timer. Time Remaining: " + str(timer.time_left) + " " + str(time_left)+ " " + str(timer.wait_time))


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
	timer = $Timer
	
	if time_left > 0:
		
		
		if timer != null:
			start_time = end_time - despawn_timer
			
			if debug_prints:
				print("timer is: " + str(timer))
				print("Restored Start Time is: " + str(start_time))
				
			if !time_passes_when_unloaded:
				timer.wait_time = time_left # time does NOT progress when unloaded
				
				if timer.is_stopped():
					timer.start()
				
				if debug_prints:
					print("Loaded time_left variable: " + str(time_left))
					
			else:
				current_time = Time.get_unix_time_from_system()
				var final_wait_time: float = end_time - current_time
				loaded_time_left = final_wait_time
				if timer.paused:
					timer.paused = false
					
				if timer.is_stopped():
					print("timer was stopped")
					timer.start()
				
				if final_wait_time > 0:
					timer.wait_time = final_wait_time # time does progress when unloaded
					
					if debug_prints:
						print("Final timer.wait_time variable: " + str(timer.wait_time))
				else:
					_on_despawn_timer_timeout()
					if debug_prints:
						print("Allotted time for existence has passed. Proceeding to despawning.")
	else:
		_on_despawn_timer_timeout()
	
	object_state_updated.emit(interaction_text)


# Custom save function to keep a few more properties.
func save():
	
	current_time = Time.get_unix_time_from_system()
	var remaining_time = end_time - current_time
	
	if remaining_time > 0:
		time_left = remaining_time
		timer.stop()
		
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
		"timer" : timer,
		
	}
	return node_data
	
