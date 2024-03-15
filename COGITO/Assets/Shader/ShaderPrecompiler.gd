extends Node3D
class_name ShaderPrecompiler

static var scene = preload("./ShaderLoader.tscn")
static var shader_compiler_scene = null
static var quad = null

var materials : Array[ShaderMaterial]

const SHADER_LAYER = 19

var is_rendering : bool = false # debugging
static var queued = false

# UNKNOWN: MultimeshInstances? Particles?
static func precompile(tree : SceneTree, shader : ShaderMaterial):
	if shader_compiler_scene == null:
		shader_compiler_scene = scene.instantiate()
		tree.root.get_camera_3d().add_child(shader_compiler_scene)
		quad = shader_compiler_scene.get_node("./SubViewport/QuadRender")
	
	shader_compiler_scene.materials.push_back(shader)
	if not queued:
		queued = true

func _process(delta):
	if not queued:
		return
	if len(shader_compiler_scene.materials) == 0:
		queued = false
		shader_compiler_scene.queue_free()
	else:
		var mat = shader_compiler_scene.materials.pop_back()
		shader_compiler_scene.material_override = mat

func _on_visible_on_screen_notifier_3d_screen_entered():
	is_rendering = true

func _on_visible_on_screen_notifier_3d_screen_exited():
	is_rendering = false


func _on_visible_on_screen_notifier_3d_tree_exiting():
	if shader_compiler_scene == self:
		# unexpected exit?
		queued = false
		queue_free()
		shader_compiler_scene = null
