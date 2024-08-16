@tool
extends CSGBox3D
class_name WaterMaker3D

@export var water_texture_move_speed := Vector3(0.0025, 0.0025, 0.0025)
@export var water_texture_uv_scale := 0.04
@export var water_color := Color(0.3098039329052, 0.54117649793625, 0.86666667461395, 0.38823530077934)
@export var fog_color := Color(0, 0.04313725605607, 0.15686275064945)
@export_range(0.0, 250.0) var fog_fade_dist := 5.0

static var last_frame_drew_underwater_effect : int = -999

func _ready():
	self.process_priority = 999 # Call _process last to update move after any camera movement

# Track the current camera with an area so we can check if it is inside the water
func should_draw_camera_underwater_effect():
	var camera := get_viewport().get_camera_3d() if get_viewport() else null
	if not camera: return false
	var aabb = self.global_transform * self.get_aabb().grow(0.025)
	if not aabb.has_point(camera.global_position): return false
	# Don't draw multiple overlays at once, incase 2 water bodies overlap
	if last_frame_drew_underwater_effect == Engine.get_process_frames(): return false
	
	%CameraPosShapeCast3D.global_position = camera.global_position
	%CameraPosShapeCast3D.force_shapecast_update()
	for i in %CameraPosShapeCast3D.get_collision_count():
		if %CameraPosShapeCast3D.get_collider(i) == %SwimmableArea3D:
			return true
	return false

func _update_mesh():
	if get_node_or_null("%CollisionShape3D"):
		%CollisionShape3D.shape.size = self.size

func _process(delta):
	_update_mesh()
	if self.material is StandardMaterial3D:
		if not Engine.is_editor_hint():
			self.material.uv1_offset += water_texture_move_speed * delta
		self.material.uv1_scale = Vector3(water_texture_uv_scale,water_texture_uv_scale,water_texture_uv_scale)
		self.material.albedo_color = water_color
	%FogVolume.material.set_shader_parameter("albedo", fog_color)
	%FogVolume.material.set_shader_parameter("emission", fog_color)
	%FogVolume.size = self.size
	%FogVolume.fade_distance = self.fog_fade_dist
	if not Engine.is_editor_hint():
		if should_draw_camera_underwater_effect():
			%WaterRippleOverlay.visible = true
			%FogVolume.material.set_shader_parameter("edge_fade", 0.1)
			last_frame_drew_underwater_effect = Engine.get_process_frames()
		else:
			%WaterRippleOverlay.visible = false
			%FogVolume.material.set_shader_parameter("edge_fade", 1.1)
