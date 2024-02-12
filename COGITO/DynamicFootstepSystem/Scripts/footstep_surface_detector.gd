extends AudioStreamPlayer3D

class_name FootstepSurfaceDetector

@export var generic_fallback_footstep_profile : AudioStreamRandomizer
@export var footstep_material_library : FootstepMaterialLibrary

func _ready():
	if not generic_fallback_footstep_profile:
		printerr("FootstepSurfaceDetector - No generic fallback footstep profile is assigned")

func play_footstep():
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3(0, -1, 0))
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		
		if _play_by_footstep_surface(result.collider):
			return
		elif _play_by_material(result.collider):
			return
		#if no material, play generics
		else:
			_play_footstep(generic_fallback_footstep_profile)

func _play_by_footstep_surface(collider : Node3D) -> bool:
	#check for footstep surface as a child of the collider
	var footstep_surface_child : AudioStreamRandomizer = _get_footstep_surface_child(collider)
	#if a child footstep surface was found, then play the sound defined by it
	if footstep_surface_child:
		_play_footstep(footstep_surface_child)
		return true
	#handle footstep surface settings
	elif collider is FootstepSurface and collider.footstep_profile:
		_play_footstep(collider.footstep_profile)
		return true
	return false

func _play_by_material(collider : Node3D) -> bool:
	# if no footstep surface, see if we can get a material
	if footstep_material_library:
		#find surface material
		var material : Material = _get_surface_material(collider)
		#if a material was found
		if material:
			#get a profile from our library
			var footstep_profile = footstep_material_library.get_footstep_profile_by_material(material)
			#found profile, use it
			if footstep_profile:
				_play_footstep(footstep_profile)
				return true
	return false

func _get_footstep_surface_child(collider : Node3D) -> AudioStreamRandomizer:
	#find all children of the collider static body that are of type "FootstepSurface"
	var footstep_surfaces = collider.find_children("", "FootstepSurface")
	if footstep_surfaces:
		#use the first footstep_surface child found
		return footstep_surfaces[0].footstep_profile
	return null

func _get_surface_material(collider : Node3D) -> Material:
	if collider is CSGShape3D:
		return collider.material
	elif collider is StaticBody3D or collider is RigidBody3D:
		#find all children of the collider static body that are of type "MeshInstance3D"
		#if there are multiple materials, just default to the first one found
		var mesh_instances = collider.find_children("", "MeshInstance3D")
		if mesh_instances:
			return mesh_instances[0].mesh.material
	return null

func _play_footstep(footstep_profile : AudioStreamRandomizer):
	stream = footstep_profile
	play()
