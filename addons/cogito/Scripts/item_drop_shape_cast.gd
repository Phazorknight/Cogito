extends ShapeCast3D

## Helper function to always get raycast destination point
func get_shapecast_item_drop_position(distance_offset: float) -> Vector3:
	var shapecast_safety_offset = get_closest_collision_safe_fraction()
	var destination_point = self.global_position + (self.target_position.z - distance_offset) * get_viewport().get_camera_3d().get_global_transform().basis.z

	return destination_point
