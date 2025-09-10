extends Area2D
class_name FluidArea2D

@export var density: float = 1.0
@export var simulate_turbulence := true

@onready var time := 0.0
@onready var noise := FastNoiseLite.new()
var surface_height: float = 0.0

func _ready() -> void:
	surface_height = position.y
	for owner_id in get_shape_owners():
		var collision = shape_owner_get_owner(owner_id)
		if collision is CollisionShape2D:
			var shape: Shape2D = collision.shape
			if shape is RectangleShape2D:
				var collision_top = Vector2(0.0, -shape.size.y * 0.5)
				var v = collision.transform * collision_top
				surface_height += (collision.transform * collision_top).y
				break

	body_entered.connect(body_enter)
	body_exited.connect(body_exit)


func _physics_process(delta: float) -> void:
	time += delta


func body_enter(body: PhysicsBody2D) -> void:
	if body.has_method("fluid_area_enter"):
		body.fluid_area_enter(self)


func body_exit(body: PhysicsBody2D) -> void:
	if body.has_method("fluid_area_exit"):
		body.fluid_area_exit(self)


func get_height(pos: Vector2) -> float:
	return surface_height - 10.0 * noise.get_noise_2d(time * 2.0 + pos.x, time * 5.0 + pos.y)	
