extends Node3D
class_name ShaderSpace

var _shader_override_enabled : bool = false
@export var shader_override_enabled : bool = false:
	get:
		return _shader_override_enabled
	set(value):
		set_override(value)
@export var shader_override : Shader
var tracked_nodes : Array[GeometryInstance3D] = []
static var standard_properties : Array[String] = []

func set_override(state : bool):
	if shader_override:
		_shader_override_enabled = state
		for node in tracked_nodes:
			node.set_instance_shader_parameter("viewmodel_enabled",_shader_override_enabled)

static func get_standard_properties() -> Array[String]:
	if not len(standard_properties):
		for property in StandardMaterial3D.new().get_property_list():
			standard_properties.push_back(property.name)
	return standard_properties
	
# Called when the node enters the scene tree for the first time.
func _ready():
	if not shader_override:
		print("WARNING: No viewmodel shader set")
		_shader_override_enabled = false
		return
	
	convert_surfaces.call_deferred()

func convert_mesh(mesh : Mesh):
	for surface in range(mesh.get_surface_count()):
		mesh.surface_set_material(surface,convert_surface(mesh.surface_get_material(surface)))

func convert_children(node):
	for child in node.get_children():
		convert_children(child)
	if node is MeshInstance3D:
		tracked_nodes.push_back(node)
		for surface in range(node.get_surface_override_material_count()):
			var premat = node.get_surface_override_material(surface)
			if premat == null:
				premat = node.mesh.surface_get_material(surface)
			var newmat = convert_surface(premat)
			node.set_surface_override_material(surface,newmat)
			print(newmat)
	elif node is CSGShape3D:
		tracked_nodes.push_back(node)
		for mesh in node.get_meshes():
			if mesh is Transform3D:
				continue
			convert_mesh(mesh)
	elif node is GeometryInstance3D:
		tracked_nodes.push_back(node)
		var mat = node.material_override or node.material_overlay
		if mat:
			node.material_override = convert_surface(mat)

func convert_surfaces():
	convert_children(self)

func convert_surface(mat : BaseMaterial3D):
	if not mat is StandardMaterial3D:
		print("WARNING: Cannot convert ", mat, " to viewmodel shader")
	else:
		var newmaterial = ShaderMaterial.new()
		newmaterial.shader = shader_override
		for param in newmaterial.shader.get_shader_uniform_list():
			if param.name in get_standard_properties():
				var mat_version = mat.get(param.name)
				if mat_version:
					newmaterial.set_shader_parameter(param.name,mat_version)
		return newmaterial
