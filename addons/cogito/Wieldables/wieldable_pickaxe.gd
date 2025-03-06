extends CogitoWieldable

@export_group("Pickaxe Settings")
@export var damage_area : Area3D
@export var uses_stamina : bool = false
@export var stamina_cost : int = 4
##Collision hit can be defined using Camera-Collider raycast, or Hitbox-Collider raycast. Camera-Collider is more reliable but less accurate, Hitbox-collider is more accurate but less reliable
@export var use_camera_collision : bool

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
		CogitoGlobals.debug_log(true, "CogitoWieldable", "No player stamina attribute found.")
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
			CogitoGlobals.debug_log(true, "CogitoWieldable", "Not enough stamina!")
			return
		else:
			player_stamina.subtract(stamina_cost)
	
	animation_player.play(anim_action_primary)
	audio_stream_player_3d.stream = swing_sound
	audio_stream_player_3d.play()


func _on_body_entered(collider):
	if collider.has_signal("damage_received"):
		var player = player_interaction_component.get_parent()
		var hit_position : Vector3
		var bullet_direction : Vector3

		if use_camera_collision:
			#Camera-Collider raycast
			hit_position = player_interaction_component.Get_Camera_Collision()
			bullet_direction = (hit_position - player.get_global_transform().origin).normalized()
		else:
			#Hitbox-Collider raycast
			var space_state = damage_area.get_world_3d().direct_space_state
			var hitbox_origin = damage_area.global_transform.origin
			var ray_params = PhysicsRayQueryParameters3D.new()
			ray_params.from = hitbox_origin
			ray_params.to = collider.global_transform.origin
			var result = space_state.intersect_ray(ray_params)
			if result.size() > 0:
				hit_position = result.position
				bullet_direction = (hit_position - hitbox_origin).normalized()
		
		collider.damage_received.emit(item_reference.wieldable_damage, bullet_direction, hit_position)
