extends Node3D
class_name ShaderSpace

var tracked_nodes : Array[GeometryInstance3D] = []

var injected_vars : String

var injected_vertex : String

func _ready():
	convert_surfaces.call_deferred()

func set_instance_shader_parameter(parameter_name : String, state : bool):
	for node in tracked_nodes:
		node.set_instance_shader_parameter(parameter_name,state)

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
		print("WARNING: Cannot convert ", mat, " to shader material")
	else:
		var newmaterial = Material3DConversion.convert_to_shadermat(mat,injected_vars,injected_vertex)
		return newmaterial
