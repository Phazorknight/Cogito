extends Node3D

var is_open : bool = false
var is_moving : bool = false

@onready var audio_stream_player_3d = $AudioStreamPlayer3D

@export_group("Audio")
@export var open_sound : AudioStream
@export var close_sound : AudioStream
@export var rattle_sound : AudioStream
@export var unlock_sound : AudioStream

@export_group("Door Parameters")
## Text that appears on the interaction prompt
@export var interaction_text : String = "Open door"
@export var is_locked : bool = false
## Item resources that is needed to unlock the door.
@export var key : InventoryItemPD
## Hint that is displayed if the player attempts to open the door but doesn't have the key item.
@export var key_hint : String
@export var open_rotation : float = 0.0
@export var closed_rotation : float = 0.0
## Speed in which the door moves between open and closed position. Usually around 0.1.
@export var door_speed : float = .1

var target_rotation : float = rotation.y

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
	
	
func _physics_process(delta):
	if is_moving:
		rotation.y = lerp_angle(rotation.y, target_rotation, door_speed)
		
	if  abs(rotation.y - target_rotation) <= 0.01: 
		is_moving = false
	
	
func open_door():
	audio_stream_player_3d.stream = open_sound
	audio_stream_player_3d.play()
	
	target_rotation = open_rotation
	is_moving = true
	is_open = true
	
func close_door():
	audio_stream_player_3d.stream = close_sound
	audio_stream_player_3d.play()
	
	target_rotation = closed_rotation
	is_moving = true
	is_open = false
