extends Node3D
class_name PlayerInteractionComponent

# Signals for UI/HUD use
signal interaction_prompt(interaction_text: String)
signal hint_prompt(hint_icon: Texture2D, hint_text: String)
signal updated_wieldable_data(wielded_item: WieldableItemPD, ammo_in_inventory: int, ammo_item: AmmoItemPD)
# Signals for Interaction raycast system
signal interactive_object_detected(interaction_nodes: Array[Node])
signal nothing_detected()
signal started_carrying(interaction_node: Node)
signal update_crosshair(is_visible: bool)

var look_vector: Vector3
var device_id: int = -1  # Used for displaying correct input prompts depending on input device.

## Raycast3D for interaction check.
@export var interaction_raycast: InteractionRayCast
@export var carryable_position: Node3D

var interactable: # Updated via signals from InteractionRayCast
	set = _set_interactable

var carried_object = null:  # Used for carryable handling.
	set = _set_carried_object
	
var is_carrying: bool:
	get: return carried_object != null

# Power with which object are thrown (opposed to being dropped)
#@export var throw_power: float = 10
@export_group("Throw Settings")
## The maximum power you can apply to a thrown object
@export var max_throw_power: float = 25.0
## Multiplied with the mass of the thrown object, up to the Max Throw Power. Prevents throwing lightweight objects incredibly fast.
@export var throw_power_mass_multiplier: float = 10.0
## Drain stamina if calculated throw power exceeds this value
@export var throw_stamina_threshold: float = 20.0
@export var throw_stamina_drain: float = 5.0
## When stamina is below cost on a throw attempt, drop instead
@export var drop_when_cant_throw: bool = true
## Leave empty to ignore stamina cost evaluation when throwing
@export var stamina_attribute: CogitoAttribute
var player: CogitoPlayer

@export_group("Drop Settings")
## The maximum power you can use when dropping objects
@export var max_drop_power: float = 1.0
## Multiplied by the mass of the thrown object, up to the Max Drop Power
@export var drop_power_mass_multiplier: float = 1.0

@export_group("Wieldable Settings")
## List of Wieldable nodes
@export var wieldable_nodes: Array[Node]
@export var wieldable_container: Node3D
var is_changing_wieldables: bool = false # Used to avoid any input acitons while wieldables are being swapped
# Various variables used for wieldable handling
var equipped_wieldable_item: WieldableItemPD = null
var equipped_wieldable_node = null
var wieldable_was_on: bool = false
var is_wielding: bool:
	get: return equipped_wieldable_item != null
	
var player_rid
# Briefly interrupt quickslot cycling after an interactable is unseen
var can_cycle_quickslots: bool = true
@onready var cycle_quickslots_interrupt_timer: Timer = $Timer


func _ready():
	player = get_parent() as CogitoPlayer
	cycle_quickslots_interrupt_timer.connect("timeout", Callable(self, "_on_can_cycle_quickslots_timeout"))


func exclude_player(rid: RID):
	player_rid = rid
	interaction_raycast.add_exception_rid(rid)


func _process(_delta):
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("interact2"):
		var action: String = "interact" if event.is_action_pressed("interact") else "interact2"
		# if carrying an object, drop it.
		_handle_interaction(action)
	
	
	if is_carrying and !get_parent().is_movement_paused and is_instance_valid(carried_object):
		if Input.is_action_just_pressed("action_primary"):
			_attempt_throw()
			#carried_object.throw(throw_power)
	
	
	# Wieldable primary Action Input
	if is_wielding and !get_parent().is_movement_paused:
		if Input.is_action_just_pressed("action_primary"):
			attempt_action_primary(false)
		if Input.is_action_just_released("action_primary"):
			attempt_action_primary(true)
		
		if Input.is_action_just_pressed("action_secondary"):
			attempt_action_secondary(false)
		if Input.is_action_just_released("action_secondary"):
			attempt_action_secondary(true)
		
		if event.is_action_pressed("reload"):
			attempt_reload()
			return

func _handle_interaction(action: String) -> void:
	# if carrying an object, drop it.
	if is_carrying:
		if is_instance_valid(carried_object):
			if carried_object.input_map_action == action:
				_drop_carried_object()
				#carried_object.throw(1)
				return
			else:
				# Allow 'take' input actions for the carried object
				var carry_parent: CogitoObject = carried_object.get_parent() as CogitoObject
				if carry_parent:
					for node: InteractionComponent in carry_parent.interaction_nodes:
						if node.input_map_action == action and not node.is_disabled:
							if node is PickupComponent or node is BackpackComponent or node is ExtendedPickupInteraction:
								if !node.ignore_open_gui and get_parent().is_showing_ui:
									return
								node.interact(self)
								
								#Dual interaction components need to await signal to update correctly
								if node is DualInteraction or node is ExtendedPickupInteraction:
									await node.interaction_complete  # Wait until the interaction_complete signal is recieved
									_rebuild_interaction_prompts()  # rebuild prompt after signal is received
								else:
									# Update the prompts after an interaction. This is especially crucial for doors and switches.
									_rebuild_interaction_prompts()
								break
		else:
			stop_carrying()
			return

	# Check if we have an interactable in view and are pressing the correct button
	if interactable != null and not is_carrying:
		for node: InteractionComponent in interactable.interaction_nodes:
			if node.input_map_action == action and not node.is_disabled:
				if !node.ignore_open_gui and get_parent().is_showing_ui:
					return
				node.interact(self)
				
				#Dual interaction components need to await signal to update correctly
				if node is DualInteraction or node is ExtendedPickupInteraction:
					#(player.player_hud as CogitoPlayerHudManager).hold_ui.
					await node.interaction_complete  # Wait until the interaction_complete signal is recieved
					_rebuild_interaction_prompts()  # rebuild prompt after signal is received
				else:
					# Update the prompts after an interaction. This is especially crucial for doors and switches.
					_rebuild_interaction_prompts()
				break


func is_interaction_raycast_colliding() -> bool:
	if interaction_raycast.is_colliding():
		return true
	else:
		return false


## Helper function to always get raycast destination point
func get_interaction_raycast_tip(distance_offset: float) -> Vector3:
	var destination_point = interaction_raycast.global_position + (interaction_raycast.target_position.z - distance_offset) * get_viewport().get_camera_3d().get_global_transform().basis.z
	if interaction_raycast.is_colliding():
		#if destination_point == interaction_raycast.get_collision_point():
		return interaction_raycast.get_collision_point()
	else:
		return destination_point


func get_carryable_destination_point(distance_offset: float) -> Vector3:
	if !carryable_position:
		print("PIC: Error, no carryable position reference set!")
		return self.global_position
	
	var destination_point = carryable_position.global_position - distance_offset * get_viewport().get_camera_3d().get_global_transform().basis.z
	
	if interaction_raycast.is_colliding():
		var collision_point = interaction_raycast.get_collision_point()
		
		if interaction_raycast.global_position.distance_squared_to(destination_point) < interaction_raycast.global_position.distance_squared_to(collision_point):
			return destination_point
		else:
			return collision_point
	
	return destination_point



### Carryable Management
func start_carrying(_carried_object):
	carried_object = _carried_object


func stop_carrying():
	carried_object = null
	_rebuild_interaction_prompts() # Ensures the drop prompt gets deleted


### Wieldable Management
func equip_wieldable(wieldable_item: WieldableItemPD ):
	if wieldable_item != null:
		equipped_wieldable_item = wieldable_item #Set Inventory Item reference
		# Set Wieldable node reference
		var wieldable_node = wieldable_item.build_wieldable_scene()
		wieldable_container.add_child(wieldable_node)
		equipped_wieldable_node = wieldable_node
		equipped_wieldable_node.item_reference = wieldable_item
		print("PIC: Found ", equipped_wieldable_item.name, " in wieldable node array: ", wieldable_node.name)
		equipped_wieldable_node.equip(self)
		await get_tree().create_timer(equipped_wieldable_node.animation_player.current_animation_length).timeout
		is_changing_wieldables = false
	else:
		is_changing_wieldables = false


func change_wieldable_to(next_wieldable: InventoryItemPD):
	is_changing_wieldables = true
	if equipped_wieldable_item != null:
		equipped_wieldable_item.is_being_wielded = false
		if equipped_wieldable_node != null:
			equipped_wieldable_node.unequip()
			if equipped_wieldable_node.animation_player.is_playing(): # Wait until unequip animation finishes.
				await get_tree().create_timer(equipped_wieldable_node.animation_player.current_animation_length).timeout 
	equipped_wieldable_item = null
	if equipped_wieldable_node != null:
		equipped_wieldable_node.queue_free()
	equipped_wieldable_node = null
	equip_wieldable(next_wieldable)


func attempt_action_primary(is_released: bool):
	if is_changing_wieldables: # Block action if currently in the process of changing wieldables
		return
	if equipped_wieldable_node == null:
		print("Nothing equipped, but is_wielding was true. This shouldn't happen!")
		return

	#else:
	equipped_wieldable_node.action_primary(equipped_wieldable_item, is_released)


func attempt_action_secondary(is_released: bool):
	if is_changing_wieldables: # Block action if currently in the process of changing wieldables
		return
	if equipped_wieldable_node == null:
		print("Nothing equipped, but is_wielding was true. This shouldn't happen!")
		return
	else:
		equipped_wieldable_node.action_secondary(is_released)


func attempt_reload():
	var inventory: CogitoInventory = get_parent().inventory_data
	# Some safety checks if reload should even be triggered.
	if inventory == null:
		print("Player inventory was null!")
		return

	if equipped_wieldable_node.animation_player.is_playing():
		print("Can't interrupt current action / animation")
		return

	# If the item doesn't use reloading, return.
	if equipped_wieldable_item.no_reload:
		return

	var ammo_needed: int = abs(equipped_wieldable_item.charge_max - equipped_wieldable_item.charge_current)
	if ammo_needed <= 0:
		print("Wieldable is fully charged.")
		return

	if equipped_wieldable_item.get_item_amount_in_inventory(equipped_wieldable_item.ammo_item_name) <= 0:
		CogitoGlobals.debug_log(true,"PIC", "You have no ammo for this wieldable.")
		return

	if equipped_wieldable_node.animation_player.is_playing(): # Make sure reload isn't interrupting another animation.
		return

	equipped_wieldable_node.reload()

	for slot: InventorySlotPD in inventory.inventory_slots:
		if ammo_needed <= 0:
			break
		if slot == null or slot.inventory_item.name != equipped_wieldable_item.ammo_item_name:
			continue

		var ammo_used: int
		var slot_ammo: AmmoItemPD = slot.inventory_item
		var quantity_needed: int = ceili(float(ammo_needed) / slot_ammo.reload_amount)

		if slot.quantity <= quantity_needed:
			ammo_used = slot_ammo.reload_amount * slot.quantity
			inventory.remove_slot_data(slot)
		elif slot.quantity > quantity_needed:
			ammo_used = slot_ammo.reload_amount * quantity_needed
			slot.quantity -= quantity_needed

		equipped_wieldable_item.add(ammo_used)
		ammo_needed -= ammo_used

	inventory.inventory_updated.emit(inventory)
	equipped_wieldable_item.update_wieldable_data(self)


func on_death():
	if equipped_wieldable_item:
		equipped_wieldable_item.is_being_wielded = false
	
	if carried_object:
		carried_object = null


# Function called by interactables if they need to send a hint. The signal sent here gets picked up by the Player_Hud_Manager.
func send_hint(hint_icon: Texture2D, hint_text: String):
	hint_prompt.emit(hint_icon, hint_text)


# Function to get a normalised vector3 in direction the player is looking.
func Get_Look_Direction() -> Vector3:
	var viewport = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_3d()
	return camera.project_ray_normal(viewport/2)
	

# This gets a world space collision point of whatever the camera is pointed at, depending on the equipped wieldable range.
func Get_Camera_Collision() -> Vector3:
	var viewport = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_3d()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2)*equipped_wieldable_item.wieldable_range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
	New_Intersection.exclude = [player_rid]
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Col_Point = Intersection.position
		return Col_Point
	else:
		return Ray_End


func save():
	if equipped_wieldable_node and equipped_wieldable_node.has_method("toggle_on_off"):
		wieldable_was_on = equipped_wieldable_node.is_on
	
	
	var interaction_component_data = {
	"equipped_wieldable_item": equipped_wieldable_item,
	#"equipped_wieldable_node": equipped_wieldable_node,
	"is_wielding": is_wielding,
	"wieldable_was_on" : wieldable_was_on,
	}
	return interaction_component_data


func set_state():
	### Clearing out data from previous player state
	updated_wieldable_data.emit(null, 0, null) # Clearing out wieldable HUD Data
	
	# Clearing out any instantiated wielable nodes
	var leftover_wieldable_nodes : Array[Node] = wieldable_container.get_children()
	for leftover_wieldable_node in leftover_wieldable_nodes:
		leftover_wieldable_node.queue_free()

	# Clearing out equipped wieldable node and it's reference
	if equipped_wieldable_node != null:
		equipped_wieldable_node.queue_free()
	equipped_wieldable_node = null
	
	# Now equip saved wieldable item "from scratch"
	if is_wielding and equipped_wieldable_item:
		var temp_wieldable : WieldableItemPD = equipped_wieldable_item
		equipped_wieldable_item = null
		
		temp_wieldable.is_being_wielded = false
		temp_wieldable.use(get_parent())
		
		if equipped_wieldable_node and equipped_wieldable_node.has_method("toggle_on_off") and wieldable_was_on:
			equipped_wieldable_node.toggle_flashlight(wieldable_was_on)


func _on_interaction_raycast_interactable_seen(new_interactable) -> void:
	interactable = new_interactable


func _on_interaction_raycast_interactable_unseen() -> void:
	interactable = null
	can_cycle_quickslots = false
	cycle_quickslots_interrupt_timer.start()


func _set_interactable(new_interactable) -> void:
	interactable = new_interactable
	# Ensure the drop prompt isn't cleared.
	if is_carrying:
		return
	if interactable == null:
		nothing_detected.emit()
	else:
		interactive_object_detected.emit(interactable.interaction_nodes)


func _set_carried_object(new_carried_object) -> void:
	carried_object = new_carried_object
	if carried_object != null:
		started_carrying.emit(carried_object)


func _rebuild_interaction_prompts() -> void:
	# Ensure the drop prompt isn't cleared.
	if is_carrying:
		return
	nothing_detected.emit() # Clears the prompts
	if interactable != null:
		interactive_object_detected.emit(interactable.interaction_nodes) # Builds the prompts


func _attempt_throw() -> void:
	if !is_carrying:
		return
	var carried_object_mass: float = (carried_object.get_parent() as RigidBody3D).mass
	var throw_force: float = carried_object_mass * throw_power_mass_multiplier
	throw_force = clamp(throw_force, 0, max_throw_power)
	
	if stamina_attribute and throw_force >= throw_stamina_threshold:
		if stamina_attribute.value_current < throw_stamina_drain:
			if drop_when_cant_throw:
				_drop_carried_object()
			return
		else:
			player.decrease_attribute(stamina_attribute.attribute_name, throw_stamina_drain)

	carried_object.throw(throw_force)


func _drop_carried_object() -> void:
	if !is_carrying:
		return
	var carried_object_mass: float = (carried_object.get_parent() as RigidBody3D).mass
	var drop_force: float = carried_object_mass * drop_power_mass_multiplier
	drop_force = clamp(drop_force, 0, max_drop_power)
	carried_object.throw(drop_force)


## Briefly interrupt quickslot cycling after an interactable is unseen
## This prevents incidental quickslot cycling when only attempting to interact with an item in the world that uses the same input action
func _on_can_cycle_quickslots_timeout() -> void:
	can_cycle_quickslots = true
