extends Node3D


@export_group("Pistol Settings")
## Path to the projectile prefab scene
@export var projectile_prefab : PackedScene
## Speed the projectile spawns with
@export var projectile_velocity : float
## Node the projectile spawns at
@onready var bullet_point = $Bullet_Point

## The Field Of View change when aiming down sight. In degrees.
@export var ads_fov = 65
@export var default_position : Vector3

@export_group("Audio")
@export var sound_primary_use : AudioStream
@export var sound_secondary_use : AudioStream
@export var sound_reload : AudioStream

# Stores the player interaction component
var player_interaction_component


# This gets called by player interaction compoment when the wieldable is equipped and primary action is pressed
func action_primary(_camera_collision:Vector3, _passed_item_reference : InventoryItemPD):
	var Direction = (_camera_collision - bullet_point.get_global_transform().origin).normalized()
	
	var Projectile = projectile_prefab.instantiate()
	bullet_point.add_child(Projectile)
	Projectile.damage_amount = _passed_item_reference.wieldable_damage
	Projectile.set_linear_velocity(Direction * projectile_velocity)
	Audio.play_sound_3d(sound_primary_use).global_position = self.global_position
	print("Pistol.gd: action_primary called. Self: ", self)


func action_secondary(is_released:bool):
	var camera = get_viewport().get_camera_3d()
	if is_released:
		# ADS Camera Zoom OUT
		var tween_cam = get_tree().create_tween()
		tween_cam.tween_property(camera,"fov", 75, .2)
		var tween_pistol = get_tree().create_tween()
		tween_pistol.tween_property(self,"position", default_position, .2)
	else:
		# ADS Camera Zoom IN
		var tween_cam = get_tree().create_tween()
		tween_cam.tween_property(camera,"fov", ads_fov, .2)
		var tween_pistol = get_tree().create_tween()
		tween_pistol.tween_property(self,"position", Vector3(0,default_position.y,default_position.z), .2)
		
