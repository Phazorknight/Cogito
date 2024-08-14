extends FogVolume

@export var fade_distance := 5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	if cam:
		var fade_plane_normal = cam.global_transform.basis.z * -1
		var fade_plane_pos = cam.global_transform.origin + cam.global_transform.basis.z * -fade_distance
		var fade_plane_distance = fade_plane_pos.dot(fade_plane_normal)
		var fade_plane = Vector4(fade_plane_normal.x, fade_plane_normal.y, fade_plane_normal.z, fade_plane_distance)
		self.material.set_shader_parameter("fade_plane", fade_plane)
