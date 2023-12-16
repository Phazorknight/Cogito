extends RigidBody3D

@export_group("Flashlight Settings")
## Matching inventory item resource.
@export var slot_data : InventorySlotPD
## The propt that appears when the player hovers on the flashlight.
@export var interaction_text : String = "Pick up Flashlight"
## Sets if the flashlight is turned on or off on ready()
@export var is_on : bool
## How much the energy depletes per second.
@export var drain_rate : float = 1

@export_group("Audio")
@export var switch_sound : AudioStream

@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var spot_light_3d = $SpotLight3D

# Stores the player interaction component
var wielder
var trigger_has_been_pressed : bool = false


func _ready():
	if is_on:
		spot_light_3d.show()
	else:
		spot_light_3d.hide()


func _process(delta):
	if is_on:
		slot_data.inventory_item.subtract(delta * drain_rate)
		if slot_data.inventory_item.charge_current == 0:
			turn_off()
			is_on = false


# Action called by the Player Interaction Component when flashlight is wielded.
func action_primary(_camera_collision:Vector3):
	toggle_on_off()

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
	elif slot_data.inventory_item.charge_current == 0:
		wielder.send_hint(null, slot_data.inventory_item.name + " is out of battery.")
	else:
		spot_light_3d.show()
		is_on = true


## Picking up the Flashlight on player interaction
func interact(body):
	if body.get_parent().inventory_data.pick_up_slot_data(slot_data):
		Audio.play_sound(slot_data.inventory_item.sound_pickup)
		body.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.") # Sending a hint that uses the default icon
		queue_free()
		
	
func throw(power):
	audio_stream_player_3d.stream = slot_data.inventory_item.sound_drop
	audio_stream_player_3d.play()
	apply_central_impulse(wielder.look_vector * Vector3(power, power, power))
