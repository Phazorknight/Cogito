##Credit to Majikayo Games SimpleFPSController for this code
##https://github.com/majikayogames/SimpleFPSController

class_name BulletDecalPool

const MAX_BULLET_DECALS = 1000
static var decal_pool := []

static func spawn_bullet_decal(global_pos : Vector3, normal : Vector3, parent : Node3D, bullet_basis : Basis, texture_override = null):
	var decal_instance : Node3D
	if len(decal_pool) >= MAX_BULLET_DECALS and is_instance_valid(decal_pool[0]):
		decal_instance = decal_pool.pop_front()
		decal_pool.push_back(decal_instance)
		decal_instance.reparent(parent)
	else:
		decal_instance = preload("res://addons/cogito/Assets/VFX/Impacts/bullet_decal.tscn").instantiate()
		parent.add_child(decal_instance)
		decal_pool.push_back(decal_instance)
	
	# Clear invalid if necessary. Parent may have gotten .queue_free()'d
	if not is_instance_valid(decal_pool[0]):
		decal_pool.pop_front()
	
	# Rotate decal towards player for things like horizontal knife slash decals
	decal_instance.global_transform = Transform3D(bullet_basis, global_pos) * Transform3D(Basis().rotated(Vector3(1,0,0), deg_to_rad(90)), Vector3())
	# Align to surface
	decal_instance.global_basis = Basis(Quaternion(decal_instance.global_basis.y, normal)) * decal_instance.global_basis
	
	#decal_instance.get_node("GPUParticles3D").emitting = true
	
	if texture_override is Texture2D:
		decal_instance.texture_albedo = texture_override
