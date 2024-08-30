extends FootstepSurfaceDetector

class_name LandingPlayer

@export var generic_fallback_landing_profile : AudioStreamRandomizer
@export var landing_material_library : FootstepMaterialLibrary

func _ready():
	if not generic_fallback_landing_profile:
		printerr("LandingPlayer - No generic fallback landing profile is assigned")

func play_landing():
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3(0, -1, 0))
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		last_result = result
		if _play_by_landing_surface(result.collider):
			return
		elif _play_by_material(result.collider):
			return
		else:
			_play_footstep(generic_fallback_landing_profile)

func _play_by_landing_surface(collider: Node3D) -> bool:
	return _play_by_footstep_surface(collider)

func _play_by_material(collider: Node3D) -> bool:
	if landing_material_library:
		var material : Material = _get_surface_material(collider)
		if material:
			var landing_profile = landing_material_library.get_footstep_profile_by_material(material)
			if landing_profile:
				_play_footstep(landing_profile)
				return true
	return false
