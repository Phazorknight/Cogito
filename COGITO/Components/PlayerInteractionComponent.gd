extends Node3D
class_name PlayerInteractionComponent

# Signals for UI/HUD use
signal interaction_prompt(interaction_text : String)
signal hint_prompt(hint_icon:Texture2D, hint_text: String)
signal set_use_prompt(use_text:String)
signal updated_wieldable_data(wieldable_icon:Texture2D, wieldable_text: String)

# Signals for Interaction raycast system
signal interactive_object_detected(interaction_nodes: Array[Node])
signal nothing_detected()
signal started_carrying(interaction_node: Node)

var look_vector : Vector3
var device_id : int = -1  #Used for displaying correct input prompts depending on input device.

## Raycast3D for interaction check.
@export var interaction_raycast : RayCast3D
# Various variables used for interaction raycast checks.
var is_reset : bool  = true
var object_detected : bool
var interactable
var previous_interactable

## Node3D for carryables. Carryables will be pulled toward this position when being carried.
@export var carryable_position : Node3D
var carried_object = null  #Used for carryable handling.
var throw_power : float = 1.5

## List of Wieldable nodes
@export var wieldable_nodes : Array[Node]
# Various variables used for wieldable handling
var equipped_wieldable_item = null
var equipped_wieldable_node = null
var is_wielding : bool


func _ready():
	#for node in wieldable_nodes:
		#node.hide()
	object_detected = false

func _process(_delta):
	# when carrying object, disable all other prompts.
	if carried_object:
		pass
	elif interaction_raycast.is_colliding():
		interactable = interaction_raycast.get_collider()
		is_reset = false
		if interactable != null and interactable.is_in_group("interactable") and !object_detected:
			interactive_object_enter(interactable)
		else:
			if interactable == null or !interactable.is_in_group("interactable") or interactable != previous_interactable:
				interactive_object_exit()

	else:
		if !is_reset:
			interactive_object_exit()
			is_reset = true
		
	# VECTOR 3 for where the player is currently looking
	var dir = (carryable_position.get_global_transform().origin - get_global_transform().origin).normalized()
	look_vector = dir


func interactive_object_enter(detected_object:Node3D):
	previous_interactable = detected_object
	interactive_object_detected.emit(detected_object.interaction_nodes)
	object_detected = true


func interactive_object_exit():
	nothing_detected.emit()
	object_detected = false


func _input(event):
	if event.is_action_pressed("interact"):
		
		# if carrying an object, drop it.
		if carried_object and carried_object.input_map_action == "interact":
			carried_object.throw(throw_power)
			carried_object = null
		
		# Checks if raycast is hitting an interactable object that has an interaction for this input action.
		if interaction_raycast.is_colliding():
			interactable = interaction_raycast.get_collider()
			if interactable.is_in_group("interactable"):
				for node in interactable.interaction_nodes:
					if node.input_map_action == "interact":
						node.interact(self)
		interactive_object_exit()
		if is_wielding:
			equipped_wieldable_item.update_wieldable_data(self)
	
	
	if event.is_action_pressed("interact2"):
		# if carrying an object, drop it.
		if carried_object and carried_object.input_map_action == "interact2":
			carried_object.throw(throw_power)
			carried_object = null
		
		# Checks if raycast is hitting an interactable object that has an interaction for this input action.
		if interaction_raycast.is_colliding():
			interactable = interaction_raycast.get_collider()
			if interactable.is_in_group("interactable"):
				for node in interactable.interaction_nodes:
					if node.input_map_action == "interact2":
						node.interact(self)
		interactive_object_exit()
		if is_wielding:
			equipped_wieldable_item.update_wieldable_data(self)
	
	
	# Wieldable primary Action Input
	if !get_parent().is_movement_paused:
		if is_wielding and Input.is_action_just_pressed("action_primary"):
			attempt_action_primary()
		
		if is_wielding and Input.is_action_just_pressed("action_secondary"):
			attempt_action_secondary(false)
		if is_wielding and Input.is_action_just_released("action_secondary"):
			attempt_action_secondary(true)
		
		if is_wielding and event.is_action_pressed("reload"):
			if interaction_raycast.is_colliding() and interaction_raycast.get_collider().has_method("interact"):
				return
			else:
				attempt_reload()


## Helper function to always get raycast destination point
func get_interaction_raycast_tip(distance_offset : float) -> Vector3:
	if interaction_raycast.is_colliding():
		return interaction_raycast.get_collision_point()
	else:
		var destination_point = interaction_raycast.global_position + (interaction_raycast.target_position.z - distance_offset) * get_viewport().get_camera_3d().get_global_transform().basis.z
		return destination_point



### Wieldable Management
func equip_wieldable(wieldable_item:WieldableItemPD):
	if wieldable_item != null:
		equipped_wieldable_item = wieldable_item #Set Inventory Item reference
		# Set Wieldable node reference
		for wieldable_node in wieldable_nodes:
			if wieldable_node.item_reference == equipped_wieldable_item:
				equipped_wieldable_node = wieldable_node
				print("PIC: Found ", equipped_wieldable_item.name, " in wieldable node array: ", wieldable_node.name)
				equipped_wieldable_node.equip(self)
				is_wielding = true

				
		
func change_wieldable_to(next_wieldable: InventoryItemPD):
	if equipped_wieldable_item != null:
		equipped_wieldable_item.is_being_wielded = false
		if equipped_wieldable_node != null:
			equipped_wieldable_node.unequip()
			if equipped_wieldable_node.animation_player.is_playing(): #Wait until unequip animation finishes.
				await get_tree().create_timer(equipped_wieldable_node.animation_player.current_animation_length).timeout 
	equipped_wieldable_item = null
	equipped_wieldable_node = null
	is_wielding = false
	equip_wieldable(next_wieldable)


func attempt_action_primary():
	if equipped_wieldable_node == null:
		print("Nothing equipped, but is_wielding was true. This shouldn't happen!")
		return
	if equipped_wieldable_item.charge_current == 0:
		send_hint(null, equipped_wieldable_item.name + " is out of ammo.")
	else:
		if !equipped_wieldable_node.animation_player.is_playing(): # Enforces fire rate.
			equipped_wieldable_item.subtract(1)
			equipped_wieldable_node.action_primary(Get_Camera_Collision(), equipped_wieldable_item)


func attempt_action_secondary(is_released:bool):
	if equipped_wieldable_node == null:
		print("Nothing equipped, but is_wielding was true. This shouldn't happen!")
		return
	else:
		equipped_wieldable_node.action_secondary(is_released)


func attempt_reload():
	var inventory = get_parent().inventory_data
	# Some safety checks if reload should even be triggered.
	if inventory == null:
		print("Player inventory was null!")
		return
		
	var ammo_needed : int = abs(equipped_wieldable_item.charge_max - equipped_wieldable_item.charge_current)
	if ammo_needed <= 0:
		print("Wieldable is fully charged.")
		return
		
	if equipped_wieldable_item.get_item_amount_in_inventory(equipped_wieldable_item.ammo_item_name) <= 0:
		print("You have no ammo for this wieldable.")
		return
		
	if !equipped_wieldable_node.animation_player.is_playing(): #Make sure reload isn't interrupting another animation.
		equipped_wieldable_node.reload()
		
		while ammo_needed > 0:
			if equipped_wieldable_item.get_item_amount_in_inventory(equipped_wieldable_item.ammo_item_name) <=0:
				print("No more ammo in inventory.")
				break
			for slot in inventory.inventory_slots:
				if slot != null and slot.inventory_item.name == equipped_wieldable_item.ammo_item_name and ammo_needed > 0:
					inventory.remove_item_from_stack(slot)
					ammo_needed -= slot.inventory_item.reload_amount
					if ammo_needed < 0:
						ammo_needed = 0
						
					equipped_wieldable_item.charge_current += slot.inventory_item.reload_amount
					if equipped_wieldable_item.charge_current > equipped_wieldable_item.charge_max:
						equipped_wieldable_item.charge_current = equipped_wieldable_item.charge_max
					
					print("RELOAD: Found ", slot.inventory_item.name, ". Removed one and added ", slot.inventory_item.reload_amount, " charge. Still needed: ", ammo_needed)
		
		inventory.inventory_updated.emit(inventory)
		equipped_wieldable_item.update_wieldable_data(self)



# Function called by interactables if they need to send a hint. The signal sent here gets picked up by the Player_Hud_Manager.
func send_hint(hint_icon,hint_text):
	hint_prompt.emit(hint_icon,hint_text)


func Get_Camera_Collision() -> Vector3:
	var viewport = get_viewport().get_size()
	var camera = get_viewport().get_camera_3d()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2)*equipped_wieldable_item.wieldable_range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Col_Point = Intersection.position
		return Col_Point
	else:
		return Ray_End
	
	
func save():
	var interaction_component_data = {
	"equipped_wieldable_item": equipped_wieldable_item,
	"equipped_wieldable_node": equipped_wieldable_node,
	"is_wielding": is_wielding
		
	}
	return interaction_component_data
	
func set_state():
	if equipped_wieldable_item and is_wielding:
		equip_wieldable(equipped_wieldable_item)
		equipped_wieldable_item.player_interaction_component = self
		set_use_prompt.emit(equipped_wieldable_item.primary_use_prompt)
		equipped_wieldable_item.update_wieldable_data(self)
