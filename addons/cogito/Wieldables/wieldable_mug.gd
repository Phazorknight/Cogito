extends CogitoWieldable

# Export variables for easy configuration in the Godot editor
@export_group("Mug Settings")
@export var coffee_mesh : Node3D
@export var water_mesh : Node3D

@export_group("Audio")
## Sound played when toggling the flashlight
@export var drink_sound: AudioStream
## Sound played when reloading
@export var refill_sound: AudioStream

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
	

# Function called when primary action is performed
func action_primary(_passed_item_reference: InventoryItemPD, is_released: bool):
	if is_released:
		is_action_pressed = false
		return
#	Play drinking animtion.


func set_content_meshes(_passed_content: int):
	match _passed_content:
		0: # EMPTY
			coffee_mesh.set_visible(false)
			water_mesh.set_visible(false)
		1: # WATER
			coffee_mesh.set_visible(false)
			water_mesh.set_visible(true)
		2: # COFFEE
			coffee_mesh.set_visible(true)
			water_mesh.set_visible(false)



# Function called when wieldable is unequipped
func equip(_player_interaction_component: PlayerInteractionComponent):
	animation_player.play(anim_equip)
	player_interaction_component = _player_interaction_component
	if item_reference.has_signal("contents_changed"):
		item_reference.contents_changed.connect(set_content_meshes)
		set_content_meshes(item_reference.current_content_index)

# Function called when wieldable is equipped
func unequip():
	animation_player.play(anim_unequip)
	if 	item_reference.contents_changed.is_connected(set_content_meshes):
		item_reference.contents_changed.disconnect(set_content_meshes)

# Function called when wieldable reload is attempted
func reload():
	return


# Function to play a sound
func play_sound(sound: AudioStream):
	audio_stream_player_3d.stream = sound
	audio_stream_player_3d.play()
