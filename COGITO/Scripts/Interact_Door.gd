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
## Set this to true if you're making a sliding instead of a rotating door.
@export var is_sliding : bool
## Rotation axis to use. True = use Z axis. False = use Y axis:
@export var use_z_axis : bool = false
## Rotation Y when the door is open. In degrees.
@export var open_rotation_deg : float = 0.0
## Rotation Y when the door is closed. In degrees.
@export var closed_rotation_deg : float = 0.0

@export var closed_position : Vector3
@export var open_position : Vector3
## Speed in which the door moves between open and closed position. Usually around 0.1.
@export var door_speed : float = .1

var interaction_text : String
var is_moving : bool = false
var target_rotation_rad : float 

func _ready():
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


func interact(interactor):
	if !is_locked:
		if !is_open:
			open_door()
		else:
			close_door()
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
			return
	
	if key_hint != "":
		interactor.send_hint(null,key_hint) # Sends the key hint with the default hint icon.


func unlock_door():
	audio_stream_player_3d.stream = unlock_sound
	audio_stream_player_3d.play()
	is_locked = false
	interaction_text = interaction_text_when_closed	
	
func open_door():
	audio_stream_player_3d.stream = open_sound
	audio_stream_player_3d.play()

	if !is_sliding:
		target_rotation_rad = deg_to_rad(open_rotation_deg)
		is_moving = true
	else:
		# Sliding door open.
		var tween_door = get_tree().create_tween()
		tween_door.tween_property(self,"position", open_position, door_speed)
		
	is_open = true
	interaction_text = interaction_text_when_open
	
func close_door():
	audio_stream_player_3d.stream = close_sound
	audio_stream_player_3d.play()
	
	if !is_sliding:
		target_rotation_rad = deg_to_rad(closed_rotation_deg)
		is_moving = true
	else:
		# Sliding door close
		var tween_door = get_tree().create_tween()
		tween_door.tween_property(self,"position", closed_position, door_speed)
	is_open = false
	interaction_text = interaction_text_when_closed
