extends Node3D
class_name PlayerInteractionComponent

signal interaction_prompt(interaction_text : String)
signal hint_prompt(hint_icon:Texture2D, hint_text: String)
signal set_use_prompt(use_text:String)
signal update_wieldable_data(wieldable_icon:Texture2D, wieldable_text: String)

## Raycast3D for interaction check.
@export var interaction_raycast : RayCast3D
@export var carryable_position : Node3D
@export var wieldable_nodes : Array[Node]
## Animation player for wieldables
@onready var wieldable_animation_player = $"../Neck/Head/Wieldables/WieldableAnimationPlayer"
@onready var wieldable_audio_stream_player_3d = $"../Neck/Head/Wieldables/WieldableAudioStreamPlayer3D"

var equipped_wieldable_item = null
var equipped_wieldable_node = null
var is_wielding : bool
var throw_power : float = 1.5
var look_vector : Vector3
var is_reset : bool  = true
var device_id : int = -1
var carried_object = null


func _ready():
	for node in wieldable_nodes:
		node.hide()

func _process(_delta):
	if interaction_raycast.is_colliding():
		var interactable = interaction_raycast.get_collider()
		is_reset = false
		if interactable != null and interactable.has_method("interact"):
			emit_signal("interaction_prompt", interactable.interaction_text)
		elif interactable != null and interactable.has_method("carry"):
			emit_signal("interaction_prompt", interactable.interaction_text)
		else:
			emit_signal("interaction_prompt", "")

	else:
		if !is_reset:
			emit_signal("interaction_prompt", "")
			is_reset = true
		
	# VECTOR 3 for where the player is currently looking
	var dir = (carryable_position.get_global_transform().origin - get_global_transform().origin).normalized()
	look_vector = dir


func _input(event):
	if event.is_action_pressed("interact"):
		
		if interaction_raycast.is_colliding():
			var interactable = interaction_raycast.get_collider()
			if interactable.has_method("interact"):
				interactable.interact(self)
			elif equipped_wieldable_item != null:
				if interactable.has_method("carry"):
					send_hint(null,"Can't carry an object while wielding.")
			elif interactable.has_method("carry"):
				interactable.carry(self)

		else:
			if carried_object != null and carried_object.has_method("carry"):
				emit_signal("set_use_prompt", "")
				carried_object.throw(throw_power)	

	# Wieldable primary Action Input
	if !get_parent().is_movement_paused:	
		if is_wielding and event.is_action_pressed("right_trigger"):
			if InputHelper.device != "keyboard":
				# Trying to get the Trigger axis to behave more like a button. Not really successfull yet...
				var trigger_value = event.get_action_strength("right_trigger")
				print("Trigger value: ", trigger_value)
				attempt_action_primary()

		if is_wielding and event.is_action_pressed("action_primary"):
			attempt_action_primary()


### Wieldable Management
func equip_wieldable(wieldable_item:InventoryItemPD):
	if wieldable_item != null:
		print("Attempting to equip ", wieldable_item)
		# Set Inventory Item reference
		equipped_wieldable_item = wieldable_item
		# Set Wieldable node reference
		for wieldable_node in wieldable_nodes:
			if wieldable_node.name == equipped_wieldable_item.name:
				equipped_wieldable_node = wieldable_node
				print("Found ", equipped_wieldable_item.name, " in wieldable node array: ", wieldable_node.name)
				wieldable_animation_player.queue(equipped_wieldable_item.equip_anim)
				is_wielding = true
		
		
func change_wieldable_to(next_wieldable: InventoryItemPD):
	if equipped_wieldable_item != null:
		wieldable_animation_player.queue(equipped_wieldable_item.unequip_anim)
		equipped_wieldable_item.is_being_wielded = false
	equipped_wieldable_node = null
	equipped_wieldable_item = null
	is_wielding = false
	equip_wieldable(next_wieldable)


func attempt_action_primary():
	if equipped_wieldable_node == null:
		print("Nothing equipped, but is_wielding was true. This shouldn't happen!")
		return
	if equipped_wieldable_item.charge_current == 0:
		send_hint(null, equipped_wieldable_item.name + " is out of ammo.")
	else:
		if !wieldable_animation_player.is_playing(): # Enforces fire rate.
			wieldable_animation_player.play(equipped_wieldable_item.use_anim)
			equipped_wieldable_item.subtract(1)
			equipped_wieldable_node.action_primary(Get_Camera_Collision())


# Function called by interactables if they need to send a hint. The signal sent here gets picked up by the Player_Hud_Manager.
func send_hint(hint_icon,hint_text):
	hint_prompt.emit(hint_icon,hint_text)


func Get_Camera_Collision() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2)*equipped_wieldable_item.wieldable_range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Col_Point = Intersection.position
		return Col_Point
	else:
		return Ray_End
	
	
