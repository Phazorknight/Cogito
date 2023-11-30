extends Node3D
class_name PlayerInteractionComponent

signal interaction_prompt(interaction_text : String)
signal hint_prompt(hint_icon:Texture2D, hint_text: String)
signal set_use_prompt(use_text:String)
signal update_wieldable_data(wieldable_icon:Texture2D, wieldable_text: String)

@export var interaction_raycast : RayCast3D
@export var carryable_position : Node3D

var carried_object = null
var throw_power : float = 1.5
var look_vector : Vector3
var is_reset : bool  = true
var device_id : int = -1


func _process(delta):
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
			elif carried_object != null:
				if interactable.has_method("carry"):
					print("Can't carry an object while wielding.")
			elif interactable.has_method("carry"):
				interactable.carry(self)

		else:
			if carried_object != null and carried_object.has_method("carry"):
				emit_signal("set_use_prompt", "")
				carried_object.throw(throw_power)	


# Function called by interactables if they need to send a hint. The signal sent here gets picked up by the Player_Hud_Manager.
func send_hint(hint_icon,hint_text):
	hint_prompt.emit(hint_icon,hint_text)
