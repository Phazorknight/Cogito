extends Node3D
class_name ShaderPrecompiler

static var shader_compiler = null
static var materials : Array[ShaderMaterial] = []

# UNKNOWN: MultimeshInstances? Particles?
## Returns the node being used to compile shaders
## `use_new_node` allows you to precompile multiple shaders at once by spawning a new node
## Disable process on the node if you want to choose when to precompile
static func precompile(tree : SceneTree, shader : ShaderMaterial, use_new_node : bool = false):
	materials.push_back(shader)
	
	var compiler = null
	if use_new_node or shader_compiler == null:
		if shader_compiler == null:
			shader_compiler = MeshInstance3D.new()
			compiler = shader_compiler
		else:
			compiler = MeshInstance3D.new()
		compiler.set_script(ShaderPrecompiler)
		compiler.mesh = QuadMesh.new()
		compiler.mesh.size = Vector2.ZERO
		compiler.position = Vector3(0,0,-0.1) # position self in front of camera
		
		compiler.cast_shadow = 0
		compiler.custom_aabb = AABB(compiler.position, Vector3.ONE*100) # make sure we're always rendering
		
		tree.root.get_camera_3d().add_child(compiler)
	else:
		return shader_compiler
	return compiler

# Every node will attempt to grab a material from the queue per frame. If there are no new materials to show this frame, it deletes itself.
func _process(_delta):
	if len(materials) == 0:
		if shader_compiler == self:
			shader_compiler = null
		get_parent().remove_child(self)
		queue_free()
	else:
		var mat = materials.pop_back()
		self.material_override = mat
