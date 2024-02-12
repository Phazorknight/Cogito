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
		#handle footstep surface settings
		if result.collider is FootstepSurface and result.collider.footstep_profile:
			_play_footstep(result.collider.footstep_profile)
		# if no footstep surface, see if we can get a material
		elif footstep_material_library and result.collider.material:
			#get a profile from our library
			var footstep_profile = footstep_material_library.get_footstep_profile_by_material(result.collider.material)
			#found profile, use it
			if footstep_profile:
				_play_footstep(footstep_profile)
				#did not find profile, play generic
			else:
				_play_footstep(generic_fallback_footstep_profile)
		#if no material, play generics
		else:
			_play_footstep(generic_fallback_footstep_profile)

func _play_footstep(footstep_profile : AudioStreamRandomizer):
	stream = footstep_profile
	play()
