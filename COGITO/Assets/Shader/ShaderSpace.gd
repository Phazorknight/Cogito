@tool
extends Node3D
class_name ShaderSpace
## Node to override any materials with a ShaderMaterial -- useful for applying shaders to lots of StandardMaterials
## 
## Any child (recursively) of this node will have all their StandardMaterial3Ds converted to ShaderMaterial code, allowing
## injection of custom shader code to a wide variety of ShaderMaterials.
## Includes 'injected_vars' and 'injected_vertex' as a start, though ultimately code can be modified directly via `shader.code`
##
## If you're looking for viewmodel rendering, use ViewmodelSpace.gd
## @experimental

## Godot's rendering engine will only compile a shader when it appears in the camera for the first time which can cause stutters.
## This flag will force Godot to render all shaders when this space enters the scene.
@export var precompile_on_enter : bool = true
var _bake : bool = false
## This will 'bake' the custom materials this script generates -- otherwise the materials are generated when this node enters the scene. 
## WARNING: Please note any changes you make to the *baked* versions of the Materials will not stay if/when you revert back to unbaked. 
## It is recommended to make permanent changes only on unbaked versions.
@export var bake : bool = false:
	get:
		return _bake
	set(value):
		if Engine.is_editor_hint():
			_bake = value
			convert_surfaces()
			if not connected_signal and _bake:
				child_entered_tree.connect(new_child)
				connected_signal = true
			elif connected_signal and not _bake:
				child_entered_tree.disconnect(new_child)
				connected_signal = false

var connected_signal = false

@export var tracked_nodes : Array[GeometryInstance3D]

var injected_vars : String

var injected_vertex : String

func _enter_tree():
	# Triggers the on-run compilation of materials
	if not _bake and not Engine.is_editor_hint():
		if not connected_signal and _bake:
			child_entered_tree.connect(new_child)
			connected_signal = true
		convert_surfaces()

func new_child(node : Node):
	# bake assets freshly added
	if _bake == Engine.is_editor_hint():
		convert_children.call_deferred(node)

func set_instance_shader_parameter(parameter_name : String, state : bool):
	for node in tracked_nodes:
		node.set_instance_shader_parameter(parameter_name,state)

func convert_mesh(mesh : Mesh):
	for surface in range(mesh.get_surface_count()):
		mesh.surface_set_material(surface,convert_surface(mesh.surface_get_material(surface)))

func convert_geometry(node : GeometryInstance3D):
	var mat = node.material_override or node.material_overlay
	var overlay = true if node.material_override else false
	if mat:
		if overlay:
			node.material_overlay = convert_surface(mat)
		else:
			node.material_override = convert_surface(mat)
	else:
		return null
	return node.material_overlay if overlay else node.material_override

func convert_children(node):
	for child in node.get_children():
		convert_children(child)
	
	var overwrote = false
	if node is MeshInstance3D:
		for surface in range(node.get_surface_override_material_count()):
			var premat = node.get_surface_override_material(surface)
			var override = true
			if premat == null:
				override = false
				premat = node.mesh.surface_get_material(surface)
			var newmat = convert_surface(premat)
			if not newmat:
				print("WARNING: No material found for ",node)
			else:
				var set_material = node.set_surface_override_material if override else node.mesh.surface_set_material
				set_material.call(surface,newmat)
			if not overwrote:
				# set true if *any* surface was successfully overwritten
				overwrote = newmat != null
	elif node is GeometryInstance3D:
		if node.material_override or node.material_overlay:
			overwrote = convert_geometry(node) != null
		elif node is CSGShape3D:
			if node is CSGPrimitive3D:
				var newmat = convert_surface(node.material)
				node.material = newmat
				overwrote = newmat != null
			else:
				for mesh in node.get_meshes():
					if mesh is Transform3D:
						continue
					convert_mesh(mesh)
				overwrote = true
	if overwrote:
		tracked_nodes.push_back(node)

func convert_surfaces():
	tracked_nodes = []
	convert_children(self)

## Returns null if given invalid material
func convert_surface(mat : Material):
	if not mat:
		return
	if mat is ConvertedMaterial:
		if Engine.is_editor_hint() and not _bake:
			# un-baking
			return mat.get_original_material()
		elif precompile_on_enter and not Engine.is_editor_hint():
			ShaderPrecompiler.precompile(get_tree(),mat)
		return mat
	if not mat is StandardMaterial3D:
		print("WARNING: Cannot convert ", mat, " to shader material")
	else:
		var newmaterial = Material3DConversion.convert_to_shadermat(mat,injected_vars,injected_vertex)
		if precompile_on_enter and not Engine.is_editor_hint():
			ShaderPrecompiler.precompile(get_tree(),newmaterial)
		return newmaterial
	
