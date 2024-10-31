extends CogitoWieldable

# Export variables for easy configuration in the Godot editor
@export_group("Flashlight Settings")
## Sets if the flashlight is turned on or off on ready()
@export var is_on: bool
## How much the energy depletes per second
@export var drain_rate: float = 1
## Cooldown time between toggles
@export var toggle_cooldown: float = 0.5
## Delay before registering button press
@export var button_press_delay: float = 0.1
## Delay before changing flashlight state
@export var state_change_delay: float = 0.25

@export_group("Audio")
## Sound played when toggling the flashlight
@export var switch_sound: AudioStream
## Sound played when reloading
@export var sound_reload: AudioStream

# Onready variables
## The light node that gets toggled
@onready var spot_light_3d = $SpotLight3D

### Every wieldable needs the following functions:
### equip(_player_interaction_component), unequip(), action_primary(), action_secondary(), reload()

# Internal variables
var is_action_pressed: bool = false
var can_toggle: bool = true  # If the flashlight can be toggled
var cooldown_timer: float = 0.0

func _ready():
	# Hide the wieldable mesh if it exists
	if wieldable_mesh:
		wieldable_mesh.hide()
	
	# Set initial visibility of the spotlight
	spot_light_3d.visible = is_on

func _process(delta):
	if is_on:
		# Drain battery when flashlight is on
		player_interaction_component.equipped_wieldable_item.subtract(delta * drain_rate)
		if player_interaction_component.equipped_wieldable_item.charge_current == 0:
			turn_off()
	
	# Handle toggle cooldown
	if not can_toggle:
		cooldown_timer += delta
		if cooldown_timer >= toggle_cooldown:
			can_toggle = true
			cooldown_timer = 0.0

# Function called when primary action is performed
func action_primary(_passed_item_reference: InventoryItemPD, is_released: bool):
	if is_released:
		is_action_pressed = false
		return
	
	if not is_action_pressed and can_toggle and not animation_player.is_playing():
		is_action_pressed = true
		can_toggle = false
		cooldown_timer = 0.0
		animation_player.play(anim_action_primary)
		toggle_on_off()

# Function called when wieldable is unequipped
func equip(_player_interaction_component: PlayerInteractionComponent):
	animation_player.play(anim_equip)
	player_interaction_component = _player_interaction_component

# Function called when wieldable is equipped
func unequip():
	animation_player.play(anim_unequip)
	if is_on:
		turn_off()

# Function called when wieldable reload is attempted
func reload():
	animation_player.play(anim_reload)
	play_sound(sound_reload)

# Function to explicitly turn it off for use when battery is depleted.
func turn_off():
	toggle_flashlight(false)

# Function to toggle the flashlight on or off
func toggle_on_off():
	await get_tree().create_timer(button_press_delay).timeout
	play_sound(switch_sound)
	
	# Wait for the animation to finish
	await animation_player.animation_finished
	
	if is_on:
		toggle_flashlight(false)
	elif player_interaction_component.equipped_wieldable_item.charge_current > 0:
		toggle_flashlight(true)
	else:
		player_interaction_component.equipped_wieldable_item.send_empty_hint()

# Function to set the flashlight state
func toggle_flashlight(new_state: bool):
	is_on = new_state
	spot_light_3d.visible = new_state

# Function to play a sound
func play_sound(sound: AudioStream):
	audio_stream_player_3d.stream = sound
	audio_stream_player_3d.play()
