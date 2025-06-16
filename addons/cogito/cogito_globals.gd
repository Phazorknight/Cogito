@tool
extends Node

var cogito_settings : CogitoSettings
var cogito_settings_filepath := "res://addons/cogito/CogitoSettings.tres"

### Cached settings
var is_logging : bool
var player_state_prefix : String
var scene_state_prefix : String
var default_transition_duration : float = .4

### Debug shape variables
var _debug_shape_pool : Array[MeshInstance3D]
var _box_pool := []
var _box_mesh : Mesh = null

func _ready() -> void:
	load_cogito_project_settings()


func _enter_tree() -> void:
	load_cogito_project_settings()


func load_cogito_project_settings():
	if ResourceLoader.exists(cogito_settings_filepath):
		cogito_settings = ResourceLoader.load(cogito_settings_filepath, "", ResourceLoader.CACHE_MODE_IGNORE)
		print("COGITO: cogito settings loaded: ", cogito_settings_filepath)
		
		is_logging = cogito_settings.is_logging
		player_state_prefix = cogito_settings.player_state_prefix
		scene_state_prefix = cogito_settings.scene_state_prefix
		default_transition_duration = cogito_settings.default_transition_duration
		
	else:
		print("COGITO: No cogito settings found.")


func debug_log(log_this: bool, _class: String, _message: String) -> void:
	if is_logging and log_this:
		print("COGITO: ", _class, ": ", _message)


func get_debug_line_material() -> StandardMaterial3D:
	var mat : StandardMaterial3D
	mat = StandardMaterial3D.new()
	mat.flags_unshaded = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color.AQUA
	return mat


func get_debug_box() -> MeshInstance3D:
	var mi : MeshInstance3D
	if len(_box_pool) == 0:
		mi = MeshInstance3D.new()
		if _box_mesh == null:
			_box_mesh = _create_wirecube_mesh(Color.WHITE)
		mi.mesh = _box_mesh
		add_child(mi)
	else:
		mi = _box_pool[-1]
		_box_pool.pop_back()
	return mi


func clear_debug_shape():
	for child in _debug_shape_pool:
		if is_instance_valid(child):
			child.queue_free()


func draw_box_aabb(aabb: AABB, color = Color.WHITE, linger_frames = 0):
	for child in _debug_shape_pool:
		if is_instance_valid(child):
			child.queue_free()
	var mi := get_debug_box()
	var mat := get_debug_line_material()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = aabb.get_center()
	mi.scale = aabb.size
	_debug_shape_pool.append(mi)


static func _create_wirecube_mesh(color := Color.WHITE) -> ArrayMesh:
	var n = -0.5
	var p = 0.5
	var positions := PackedVector3Array([
		Vector3(n, n, n),
		Vector3(p, n, n),
		Vector3(p, n, p),
		Vector3(n, n, p),
		Vector3(n, p, n),
		Vector3(p, p, n),
		Vector3(p, p, p),
		Vector3(n, p, p)
	])
	var colors := PackedColorArray([
		color, color, color, color,
		color, color, color, color,
	])
	var indices := PackedInt32Array([
		0, 1,
		1, 2,
		2, 3,
		3, 0,

		4, 5,
		5, 6,
		6, 7,
		7, 4,

		0, 4,
		1, 5,
		2, 6,
		3, 7
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh



func _on_check_box_print_logs_toggled(toggled_on: bool) -> void:
	is_logging = toggled_on


func _on_lineedit_fade_duration_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		default_transition_duration = float(new_text)
	else:
		push_error("Must enter valid float value.")
		default_transition_duration = .5
