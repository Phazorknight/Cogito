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
@export var pick_up_sound : AudioStream
@export var drop_sound : AudioStream
@export var switch_sound : AudioStream

@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var spot_light_3d = $SpotLight3D

# Status if the player is holding the flashlight
var is_being_wielded : bool
# Stores the player interaction component
var wielder


func _ready():
	if is_on:
		spot_light_3d.show()
	else:
		spot_light_3d.hide()


func _process(delta):
	if is_being_wielded:
		global_position = wielder.carryable_position.global_position
		global_rotation = wielder.carryable_position.global_rotation

	if is_on:
		slot_data.inventory_item.subtract(delta * drain_rate)

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


func interact(body):
	if body.get_parent().inventory_data.pick_up_slot_data(slot_data):
		AudioManagerPd.play_audio("pick_up") # Playing a sound via the AudioManager
		body.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.") # Sending a hint that uses the default icon
		queue_free()


func pick_up(player_interaction_component):
	wielder = player_interaction_component

	if wielder.carried_object == null:
		if is_being_wielded:
			leave()
		else:

			hold()
	else:
		print("Can't wield while holding an object.")


func _input(event):
	if wielder != null and !wielder.get_parent().is_movement_paused:
		if is_being_wielded and event.get_action_strength("right_trigger") >= 0.5:
			toggle_on_off()
		if is_being_wielded and event.is_action_pressed("action_primary"):
			toggle_on_off()

func hold():
	$CollisionShape3D.set_disabled(true)
	wielder.carried_object = self
	
	# Play Pick up sound.
	audio_stream_player_3d.stream = pick_up_sound
	audio_stream_player_3d.play()
	
	self.set_freeze_enabled(true)
	is_being_wielded = true

func leave():
	$CollisionShape3D.set_disabled(false)
	wielder.carried_object = null
	self.set_freeze_enabled(false)
	is_being_wielded = false
	
func throw(power):
	leave()
	if drop_sound != null:
		audio_stream_player_3d.stream = drop_sound
		audio_stream_player_3d.play()
	apply_central_impulse(wielder.look_vector * Vector3(power, power, power))
