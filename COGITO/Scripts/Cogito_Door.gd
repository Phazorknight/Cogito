extends Node3D

@onready var audio_stream_player_3d = $AudioStreamPlayer3D

@export_group("Audio")
@export var open_sound : AudioStream
@export var close_sound : AudioStream
@export var rattle_sound : AudioStream
@export var unlock_sound : AudioStream

@export_group("Door Parameters")
## Start state of the door (usually closed).
@export var is_open : bool = false
## Text that appears on the interaction prompt when locked.
@export var interaction_text_when_locked : String = "Unlock"
## Text that appears on the interaction prompt when closed.
@export var interaction_text_when_closed : String = "Open"
## Text that appears on the interaction prompt when open.
@export var interaction_text_when_open : String = "Close"
@export var is_locked : bool = false
## Item resources that is needed to unlock the door.
@export var key : InventoryItemPD
## Hint that is displayed if the player attempts to open the door but doesn't have the key item.
@export var key_hint : String
## Other doors that should sync their state (locked, unlocked, open, closed) with this door. Useful for double-doors, etc.
@export var doors_to_sync_with : Array[NodePath]

## Use these if you don't have an animation.
@export_subgroup("Tween Parameters")
## Set this to true if you're making a sliding instead of a rotating door.
@export var is_sliding : bool
## Rotation axis to use. True = use Z axis. False = use Y axis:
@export var use_z_axis : bool = false
## Set this to true if the door should swing opposite the direction of the interactor
@export var bidirectional_swing : bool = false
## Rotation Y when the door is open. In degrees.
@export var open_rotation_deg : float = 0.0
## Rotation Y when the door is closed. In degrees.
@export var closed_rotation_deg : float = 0.0
## Local position of transform when closed
@export var closed_position : Vector3
## Local position of transform when open
@export var open_position : Vector3
## Speed in which the door moves between open and closed position. Usually around 0.1.
@export var door_speed : float = .1

@export_subgroup("Animation Parameters")
@export var is_animation_based : bool = false
@export var animation_player : NodePath
@export var opening_animation : String
@export var reverse_opening_anim_for_close : bool = true
@export var closing_animation : String
var anim_player : AnimationPlayer

var interaction_text : String
var is_moving : bool = false
var target_rotation_rad : float 

func _ready():
	add_to_group("Save_object_state")
	
	if is_animation_based:
		anim_player = get_node(animation_player)
	
	if use_z_axis:
		target_rotation_rad = rotation.z
	else:
		target_rotation_rad = rotation.y
	if is_open:
		interaction_text = interaction_text_when_open
	elif is_locked:
		interaction_text = interaction_text_when_locked
	else:
		interaction_text = interaction_text_when_closed


func interact(interactor: Node3D):
	if !is_locked:
		if !is_open:
			open_door(interactor)
			
			for nodepath in doors_to_sync_with:
				if nodepath != null:
					var object = get_node(nodepath)
					object.open_door()
		else:
			close_door(interactor)
			
			for nodepath in doors_to_sync_with:
				if nodepath != null:
					var object = get_node(nodepath)
					object.close_door()
	else:
		audio_stream_player_3d.stream = rattle_sound
		audio_stream_player_3d.play()
		
		check_for_key(interactor)


func _physics_process(_delta):
	if !is_sliding:
		if is_moving:
			if use_z_axis:
				rotation.z = lerp_angle(rotation.z, target_rotation_rad, door_speed)
			else:
				rotation.y = lerp_angle(rotation.y, target_rotation_rad, door_speed)
	
		if use_z_axis and abs(rotation.z - target_rotation_rad) <= 0.01: 
			is_moving = false
		if !use_z_axis and abs(rotation.y - target_rotation_rad) <= 0.01: 
			is_moving = false
	
	
func check_for_key(interactor):
	var inventory = interactor.get_parent().inventory_data
	for slot_data in inventory.inventory_slots:
		if slot_data != null and slot_data.inventory_item == key:
			interactor.send_hint(null, key.name + " used.") # Sends a hint with the key item name.
			if slot_data.inventory_item.discard_after_use:
				inventory.remove_slot_data(slot_data)
			unlock_door()
			
			for nodepath in doors_to_sync_with:
				if nodepath != null:
					var object = get_node(nodepath)
					object.unlock_door()
			return
	
	if key_hint != "":
		interactor.send_hint(null,key_hint) # Sends the key hint with the default hint icon.


func unlock_door():
	audio_stream_player_3d.stream = unlock_sound
	audio_stream_player_3d.play()
	is_locked = false
	interaction_text = interaction_text_when_closed	
	
func open_door(interactor: Node3D):
	audio_stream_player_3d.stream = open_sound
	audio_stream_player_3d.play()

	if is_animation_based:
		anim_player.play(opening_animation)
	elif !is_sliding:
		target_rotation_rad = deg_to_rad(open_rotation_deg)
		var swing_direction: int = 1

		if bidirectional_swing:
			var offset: Vector3 = interactor.global_transform.origin - global_transform.origin
			var offset_dot_product: float = offset.dot(global_transform.basis.x)
			swing_direction = -1 if offset_dot_product < 0 else 1

		target_rotation_rad = deg_to_rad(open_rotation_deg * swing_direction)
		is_moving = true
	else:
		var tween_door = get_tree().create_tween()
		tween_door.tween_property(self,"position", open_position, door_speed)
	
	is_open = true
	interaction_text = interaction_text_when_open
	
func close_door(_interactor: Node3D):
	audio_stream_player_3d.stream = close_sound
	audio_stream_player_3d.play()
	
	if is_animation_based:
		if reverse_opening_anim_for_close:
			anim_player.play_backwards(opening_animation)
		else:
			anim_player.play(closing_animation)
	elif !is_sliding:
		target_rotation_rad = deg_to_rad(closed_rotation_deg)
		is_moving = true
	else:
		# Sliding door close
		var tween_door = get_tree().create_tween()
		tween_door.tween_property(self,"position", closed_position, door_speed)
	is_open = false
	interaction_text = interaction_text_when_closed
	
	
func set_state():
	if is_open:
		interaction_text = interaction_text_when_open
	else:
		interaction_text = interaction_text_when_closed
	if is_locked:
		interaction_text = interaction_text_when_locked
	
	
func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"is_locked" : is_locked,
		"is_open" : is_open,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
