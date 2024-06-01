extends CogitoWieldable


@export_group("Throwable Settings")
## Leave empty if projectile and pickup are the same scene
@export var projectile_override: PackedScene
## Speed the projectile spawns with
@export var projectile_velocity : float
## Node the projectile spawns at
@onready var bullet_point: Node3D = %Bullet_Point


@export_group("Audio")
@export var sound_primary_use : AudioStream
@export var sound_reload : AudioStream

var player_inventory : CogitoInventory
var item_slot : InventorySlotPD

# Function called when wieldable is unequipped.
func equip(_player_interaction_component: PlayerInteractionComponent):
	animation_player.play(anim_equip)
	player_interaction_component = _player_interaction_component
	player_inventory = player_interaction_component.get_parent().inventory_data
	item_slot = get_slot_reference()


# Function to get the AmmoItemPD
func get_slot_reference() -> InventorySlotPD:
	var slot_reference : InventorySlotPD
	if player_inventory != null:
		for slot in player_inventory.inventory_slots:
			if slot != null and slot.inventory_item.name == item_reference.name:
				slot_reference = slot
				
	return slot_reference


# This gets called by player interaction compoment when the wieldable is equipped and primary action is pressed
func action_primary(_passed_item_reference : InventoryItemPD, _is_released: bool):
	if _is_released:
		return
	
	# Not firing if animation player is playing. This enforces fire rate.
	if animation_player.is_playing():
		return
	
	# Sound and animation
	animation_player.play(anim_action_primary)
	audio_stream_player_3d.stream = sound_primary_use
	audio_stream_player_3d.play()
	
	unequip()
	
	### Reduce the stack of the dart items:
	if item_slot:
		item_slot.quantity -= 1
		if item_slot.quantity < 1:
			player_inventory.remove_slot_data(item_slot)
			item_reference.put_away()
		else:
			equip(player_interaction_component)
	
	player_inventory.inventory_updated.emit(player_inventory)
	
	# Gettting camera_collision pos from player interaction component:
	var _camera_collision = player_interaction_component.Get_Camera_Collision()
	var Direction = (_camera_collision - bullet_point.get_global_transform().origin).normalized()
	
	# Spawning projectile
	var projectile = instantiate_projectile()
	bullet_point.add_child(projectile)
	projectile.damage_amount = _passed_item_reference.wieldable_damage
	projectile.set_linear_velocity(Direction * projectile_velocity)
	projectile.reparent(get_tree().get_current_scene())


func instantiate_projectile() -> Node3D:
	if projectile_override != null:
		return projectile_override.instantiate()
	return load(item_reference.drop_scene).instantiate()
