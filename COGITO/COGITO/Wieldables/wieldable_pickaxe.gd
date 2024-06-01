extends CogitoWieldable

@export_group("Pickaxe Settings")
@export var damage_area : Area3D

@export_group("Audio")
@export var swing_sound : AudioStream

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


func _on_body_entered(collider):
	if collider.has_signal("damage_received"):
		collider.damage_received.emit(item_reference.wieldable_damage)
