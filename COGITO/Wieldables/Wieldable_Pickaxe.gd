extends Node3D

@export_group("Pickaxe Settings")
@export var damage_area : Area3D

@export_group("Audio")
@export var swing_sound : AudioStream

@export_group("General Wieldable Settings")
## Item resource that this wieldable refers to.
@export var item_reference : WieldableItemPD
## Visible parts of the wieldable. Used to hide/show on equip/unequip.
@export var wieldable_mesh : Node3D

@export_group("Animations")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_stream_player_3d = $AudioStreamPlayer3D

@export var anim_equip: String = "equip"
@export var anim_unequip: String = "unequip"
@export var anim_action_primary: String = "action_primary"
@export var anim_action_secondary: String = "action_secondary"
@export var anim_reload: String = "reload"

### Every wieldable needs the following functions:
### equip(_player_interaction_component), unequip(), action_primary(), action_secondary(), reload()

var player_interaction_component # Stores the player interaction component
var trigger_has_been_pressed : bool = false


func _ready():
	if wieldable_mesh:
		wieldable_mesh.hide()
		
	damage_area.body_entered.connect(_on_body_entered)


# Primary action called by the Player Interaction Component when flashlight is wielded.
func action_primary(_passed_item_reference:InventoryItemPD, _is_released: bool):
	if _is_released:
		return
	
	# Not swinging if animation player is playing. This enforces swing rate.
	if animation_player.is_playing():
		return
	
	animation_player.play(anim_action_primary)
	audio_stream_player_3d.stream = swing_sound
	audio_stream_player_3d.play()


# Secondary action called by the Player Interaction Component when flashlight is wielded.
func action_secondary(_is_released: bool):
	print("Pickaxe doesn't have a secondary action.")
	pass


# Function called when wieldable is unequipped.
func equip(_player_interaction_component: PlayerInteractionComponent):
	animation_player.play(anim_equip)
	player_interaction_component = _player_interaction_component


# Function called when wieldable is unequipped.
func unequip():
	animation_player.play(anim_unequip)


# Function called when wieldable reload is attempted
func reload():
	print("Pickaxe doesn't need to reload.")


func _on_body_entered(collider):
	if collider is CogitoObject:
		collider.damage_received.emit(item_reference.wieldable_damage)
