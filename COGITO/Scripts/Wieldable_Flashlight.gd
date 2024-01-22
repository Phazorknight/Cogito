extends Node3D

@export_group("Flashlight Settings")
### Matching inventory item resource.
#var slot_data : InventorySlotPD
## Sets if the flashlight is turned on or off on ready()
@export var is_on : bool
## How much the energy depletes per second.
@export var drain_rate : float = 1

@export_group("Audio")
@export var switch_sound : AudioStream
@export var sound_reload : AudioStream

@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var spot_light_3d = $SpotLight3D

# Stores the player interaction component
var player_interaction_component
var trigger_has_been_pressed : bool = false


func _ready():
	if is_on:
		spot_light_3d.show()
	else:
		spot_light_3d.hide()

func _process(delta):
	if is_on:
		player_interaction_component.equipped_wieldable_item.subtract(delta * drain_rate)
		if player_interaction_component.equipped_wieldable_item.charge_current == 0:
			turn_off()
			is_on = false


# Action called by the Player Interaction Component when flashlight is wielded.
func action_primary(_camera_collision:Vector3, _passed_item_reference:InventoryItemPD):
	toggle_on_off()
	
func action_secondary(_is_released: bool):
	print("Flashlight doesn't have a secondary action.")
	pass

# Function to explicitly turn it off for use when battery is depleted.
func turn_off():
	is_on = false
	audio_stream_player_3d.stream = switch_sound
	audio_stream_player_3d.play()
	spot_light_3d.hide()

func toggle_on_off():
	audio_stream_player_3d.stream = switch_sound
	audio_stream_player_3d.play()
	
	if is_on:
		spot_light_3d.hide()
		is_on = false
	elif player_interaction_component.equipped_wieldable_item.charge_current == 0:
		player_interaction_component.send_hint(null, player_interaction_component.equipped_wieldable_item.name + " is out of battery.")
	else:
		spot_light_3d.show()
		is_on = true
