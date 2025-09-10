extends Area3D
class_name FluidArea3D

@export var density: float = 1.0
@export var simulate_turbulence := true

@onready var time := 0.0
@onready var noise := FastNoiseLite.new()
var surface_height: float = 0.0

func _ready() -> void:
	surface_height = position.y
	for owner_id in get_shape_owners():
		var collision = shape_owner_get_owner(owner_id)
		if collision is CollisionShape3D:
			var shape: Shape3D = collision.shape
			if shape is BoxShape3D:
				var collision_top = Vector3(0.0, shape.size.y * 0.5, 0.0)
				surface_height += (collision.transform * collision_top).y
				break

	body_entered.connect(body_enter)
	body_exited.connect(body_exit)


func _physics_process(delta: float) -> void:
	time += delta


func body_enter(body: PhysicsBody3D) -> void:
	if body.has_method("fluid_area_enter"):
		body.fluid_area_enter(self)


func body_exit(body: PhysicsBody3D) -> void:
	if body.has_method("fluid_area_exit"):
		body.fluid_area_exit(self)


func get_height(pos: Vector3) -> float:
	return surface_height + 0.3 * noise.get_noise_3d(time * 2.0 + pos.x, pos.y, time * 5.0 + pos.z)	
