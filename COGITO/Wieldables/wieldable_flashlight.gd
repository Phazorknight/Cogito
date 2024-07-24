extends CogitoWieldable


@export_group("Flashlight Settings")
## Sets if the flashlight is turned on or off on ready()
@export var is_on : bool
## How much the energy depletes per second.
@export var drain_rate : float = 1
## The light node that gets toggled.
@onready var spot_light_3d = $SpotLight3D

@export_group("Audio")
@export var switch_sound : AudioStream
@export var sound_reload : AudioStream

### Every wieldable needs the following functions:
### equip(_player_interaction_component), unequip(), action_primary(), action_secondary(), reload()

var trigger_has_been_pressed : bool = false


var is_action_pressed : bool = false # Prevent flashlight failing to turn on / off while walking / running.
var can_toggle : bool = true # If the flashlight can be toggled.
var toggle_cooldown : float = 0.5  # Adjust this value to set the cooldown time for flashlight to turn on / off.
var cooldown_timer : float = 0.0


func _ready():
	if wieldable_mesh:
		wieldable_mesh.hide()
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
    
	if not can_toggle:
		cooldown_timer += delta
		if cooldown_timer >= toggle_cooldown:
			can_toggle = true
			cooldown_timer = 0.0

func action_primary(_passed_item_reference:InventoryItemPD, is_released: bool):
	if is_released:
		is_action_pressed = false
		return
    
	if not is_action_pressed and can_toggle and not animation_player.is_playing():
		is_action_pressed = true
		can_toggle = false
		cooldown_timer = 0.0
		animation_player.play(anim_action_primary)
		toggle_on_off()


# Function called when wieldable is unequipped.
func equip(_player_interaction_component: PlayerInteractionComponent):
	animation_player.play(anim_equip)
	player_interaction_component = _player_interaction_component


# Function called when wieldable is unequipped.
func unequip():
	animation_player.play(anim_unequip)
	if is_on:
		turn_off()


# Function called when wieldable reload is attempted
func reload():
	animation_player.play(anim_reload)
	audio_stream_player_3d.stream = sound_reload
	audio_stream_player_3d.play()


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