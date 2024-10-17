extends CogitoWieldable

@export_group("Pickaxe Settings")
@export var damage_area : Area3D
@export var uses_stamina : bool = false
@export var stamina_cost : int = 4

@export_group("Audio")
@export var swing_sound : AudioStream

var trigger_has_been_pressed : bool = false
var player_stamina : CogitoAttribute = null


func _ready():
	if wieldable_mesh:
		wieldable_mesh.hide()
		
	damage_area.body_entered.connect(_on_body_entered)

	if uses_stamina:
		player_stamina = grab_player_stamina_attribute()
		


func grab_player_stamina_attribute() -> CogitoAttribute:
	if CogitoSceneManager._current_player_node.stamina_attribute:
		return CogitoSceneManager._current_player_node.stamina_attribute
	else:
		print("Wieldable: No player stamina attribute found.")
		return null


# Primary action called by the Player Interaction Component when flashlight is wielded.
func action_primary(_passed_item_reference:InventoryItemPD, _is_released: bool):
	if _is_released:
		return
	
	# Not swinging if animation player is playing. This enforces swing rate.
	if animation_player.is_playing():
		return

	# Check for stamina consumption
	if uses_stamina:
		if player_stamina.value_current < stamina_cost:
			print("Wieldable: Not enough stamina!")
			return
		else:
			player_stamina.subtract(stamina_cost)
	
	animation_player.play(anim_action_primary)
	audio_stream_player_3d.stream = swing_sound
	audio_stream_player_3d.play()


func _on_body_entered(collider):
	if collider.has_signal("damage_received"):
		var player = player_interaction_component.get_parent()
		var hit_position = player_interaction_component.Get_Camera_Collision()
		var bullet_direction = (hit_position - player.get_global_transform().origin).normalized()
		collider.damage_received.emit(item_reference.wieldable_damage, bullet_direction, hit_position)

