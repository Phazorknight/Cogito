extends Node

@export var laser_material : ORMMaterial3D
@export var lifespan : float = 3.0
@onready var timer: Timer = $Timer

var mesh_instance := MeshInstance3D.new()
var immediate_mesh := ImmediateMesh.new()

var instanced_ray_material : ORMMaterial3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.wait_time = lifespan
	timer.timeout.connect(on_timer_timeout)
	timer.start()


func draw_ray(start_point: Vector3, end_point: Vector3) -> MeshInstance3D:
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_OFF
	
	instanced_ray_material = laser_material.duplicate()
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, instanced_ray_material)
	immediate_mesh.surface_add_vertex(start_point)
	immediate_mesh.surface_add_vertex(end_point)
	immediate_mesh.surface_end()
	
	add_child(mesh_instance)
	return mesh_instance
	
func on_timer_timeout():
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(instanced_ray_material,"albedo_color", Color.TRANSPARENT, 1)
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
