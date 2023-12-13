extends RigidBody3D

@export_group("Pistol Settings")
## Matching inventory item resource.
@export var slot_data : InventorySlotPD
## The propt that appears when the player hovers on the flashlight.
@export var interaction_text : String = "Pick up"
## Path to the projectile prefab scene
@export var projectile_prefab : PackedScene
@export var projectile_velocity : float
@onready var bullet_point = $Bullet_Point

@export_group("Audio")
@export var sound_primary_use : AudioStream
@export var sound_secondary_use : AudioStream
@export var sound_reload : AudioStream


# Stores the player interaction component
var wielder

# This gets called by player interaction compoment when the wieldable is equipped and primary action is pressed
func action_primary(_camera_collision:Vector3):
	var Direction = (_camera_collision - bullet_point.get_global_transform().origin).normalized()
	var Projectile = projectile_prefab.instantiate()
	
	bullet_point.add_child(Projectile)
	Projectile.damage_amount = slot_data.inventory_item.wieldable_damage
	Projectile.set_linear_velocity(Direction * projectile_velocity)
	Audio.play_sound_3d(sound_primary_use).global_position = self.global_position
	print("Pistol.gd: action_primary called. Self: ", self)


## Picking up the pistol on player interaction
func interact(body):
	if body.get_parent().inventory_data.pick_up_slot_data(slot_data):
		Audio.play_sound(slot_data.inventory_item.sound_pickup)
		body.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.") # Sending a hint that uses the default icon
		queue_free()


