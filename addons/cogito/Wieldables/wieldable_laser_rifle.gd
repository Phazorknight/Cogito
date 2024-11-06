extends CogitoWieldable

@export_group("Laser Rifle Settings")
## Determines delay between shots aka fire rate.
@export var firing_delay : float = 0.2
## Node for the laser origin
@onready var bullet_point: Node3D = %Bullet_Point
## Prefab of laser_ray
@export var laser_ray_prefab : PackedScene
## How long laser rays linger in the air
@export var ray_lifespan : float = 5.0
## The Field Of View change when aiming down sight. In degrees.
@export var ads_fov = 65
## Default position for tweening from ADS
@export var default_position : Vector3

@export_group("Collisions")
## Spawn hit decal on Collision hit
@export var decal_spawn : bool = true
## Hit decal texture, if blank will be set to default bullet decal texture
@export var decal_texture : Texture2D
## Scene that spawns when a bullet of the weapon collides with anything
@export var collision_scene : PackedScene

@export_group("Audio")
@export var sound_primary_use : AudioStream
@export var sound_secondary_use : AudioStream
@export var sound_reload : AudioStream

var spawn_node : Node
var is_firing : bool = false

var firing_cooldown : float
var player_rid : RID

var inventory_item_reference : WieldableItemPD


func _ready():
	wieldable_mesh.hide()
	firing_cooldown = 0
	player_rid = CogitoSceneManager._current_player_node.get_rid()


func _physics_process(_delta: float) -> void:
	if firing_cooldown > 0:
		firing_cooldown -= _delta
		
	if is_firing:
		if firing_cooldown <= 0:
			if animation_player.is_playing():
				return
			# Gettting camera_collision pos from player interaction component:
			var _camera_collision = player_interaction_component.Get_Camera_Collision()
			hit_scan_collision(_camera_collision) #Do the hitscan
		
			animation_player.play(anim_action_primary)
			audio_stream_player_3d.stream = sound_primary_use
			audio_stream_player_3d.play()
			
			inventory_item_reference.subtract(1) # Reduce ammo
			
			if inventory_item_reference.charge_current <= 0: # Stop firing if out of ammo in clip.
				is_firing = false
			
			firing_cooldown = firing_delay


# This gets called by player interaction compoment when the wieldable is equipped and primary action is pressed
func action_primary(_passed_item_reference : InventoryItemPD, _is_released: bool):
	inventory_item_reference = _passed_item_reference
	
	if !_is_released and inventory_item_reference.charge_current <= 0: # Can't fire if empty + send hint.
		inventory_item_reference.send_empty_hint()
		return
	if _is_released and inventory_item_reference.charge_current <= 0: # Can't fire if empty + don't send hint.
		return
	
	if _is_released:
		is_firing = false
	else:
		is_firing = true


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


func hit_scan_collision(collision_point:Vector3):
	var bullet_direction = (collision_point - bullet_point.get_global_transform().origin).normalized()
	var new_intersection = PhysicsRayQueryParameters3D.create(bullet_point.get_global_transform().origin, collision_point + bullet_direction * 2)
	new_intersection.exclude = [player_rid]
	
	var bullet_collision = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	# Spawning a laser ray
	var instantiated_ray = laser_ray_prefab.instantiate()
	instantiated_ray.draw_ray(bullet_point.get_global_transform().origin, collision_point)
	spawn_node.add_child(instantiated_ray)
	
	if bullet_collision:
		hit_scan_damage(bullet_collision.collider, bullet_direction, bullet_collision.position)
		
		if collision_scene !=null:
			hit_scan_scene(bullet_collision)
		
		if decal_spawn == true:
			var bullet_collider = bullet_collision.collider
			var bullet_collision_position = bullet_collision.position
			var bullet_collision_normal = bullet_collision.normal
			var bullet_global_basis = bullet_point.get_global_transform().basis
			# Spawn bullet decal with collision parameters
			BulletDecalPool.spawn_bullet_decal(bullet_collision_position, bullet_collision_normal, bullet_collider, bullet_global_basis,decal_texture)


func hit_scan_damage(collider, bullet_direction, bullet_position):
	if collider.has_signal("damage_received"):
		collider.damage_received.emit(item_reference.wieldable_damage,bullet_direction,bullet_position)


func hit_scan_scene(bullet_collision):
	if collision_scene !=null:
		var hit_indicator = collision_scene.instantiate()
		var world = get_tree().get_root().get_child(0)
		world.add_child(hit_indicator)
		hit_indicator.global_translate(bullet_collision.position)


# Function called when wieldable reload is attempted
func reload():
	animation_player.play(anim_reload)
	audio_stream_player_3d.stream = sound_reload
	audio_stream_player_3d.play()


# Function called when wieldable is equipped.
func equip(_player_interaction_component: PlayerInteractionComponent):
	spawn_node = get_tree().get_current_scene()
	animation_player.play(anim_equip)
	player_interaction_component = _player_interaction_component
