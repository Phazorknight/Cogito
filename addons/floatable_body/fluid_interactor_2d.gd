extends RefCounted
class_name FluidInteractor2D

class Floater2D:
	var position: Vector2
	var radius: float
	var state: int
	
	func _init(pos: Vector2, r: float):
		position = pos
		radius = r
	
	func is_in_fluid() -> bool:
		return state >= 2
	
	func is_just_entered_to_fluid() -> bool:
		return state == 2

	func is_just_exited_from_fluid() -> bool:
		return state == 1


var fluid_area: FluidArea2D = null
var volume: float = 0.0
var floaters: Array[Floater2D]
var float_position: Vector2 = Vector2.ZERO
var float_force: Vector2 = Vector2.ZERO


func _init():
	floaters = []


func process(transform: Transform2D, mass: float = 1.0, gravity_scale: float = 1.0) -> void:
	float_position = Vector2.ZERO
	float_force = Vector2.ZERO

	if fluid_area == null:
		return

	var sum_positions := Vector2.ZERO
	var sum_weights := 0.0
	var min_diff := 1000000.0
	var max_diff := 0.0
	for floater in floaters:
		var floater_position = transform * floater.position
		var surface_height = fluid_area.get_height(floater_position)
		var diff_b: float = floater_position.y + floater.radius - surface_height;
		var diff_u: float = floater_position.y - floater.radius - surface_height;
		
		min_diff = min(min_diff, diff_u)
		max_diff = max(max_diff, diff_b)
		if diff_b > 0:
			sum_positions += floater_position * diff_b
			sum_weights += diff_b
	
	if sum_weights > 0.0:
		var float_volume := volume
		var float_diff := max_diff - min_diff
		if min_diff < 0.0:
			float_volume *= max_diff / float_diff
			float_diff = max_diff

		float_position = sum_positions / sum_weights - transform.origin
		float_force = Vector2.UP * float_diff * float_volume / mass * fluid_area.density * 1000.0 * gravity_scale


func add_collision_shape(collision: CollisionShape2D) -> void:
	var shape: Shape2D = collision.shape
	if shape is RectangleShape2D:
		var extent: Vector2 = shape.size * 0.5
		add_floater(collision.transform * Vector2(-extent.x, 0.0), extent.y)
		add_floater(collision.transform * Vector2( extent.x, 0.0), extent.y)
		volume += shape.size.x * shape.size.y / 10000
	elif shape is CircleShape2D:
		add_floater(collision.position, shape.radius)
		volume += PI * pow(shape.radius, 2.0) / 10000
	elif shape is CapsuleShape2D:
		add_floater(collision.transform * Vector2(0.0, -shape.height * 0.5), shape.radius)
		add_floater(collision.transform * Vector2(0.0, +shape.height * 0.5), shape.radius)
		volume += (PI * pow(shape.radius, 2.0) + shape.radius * 2 * shape.height) / 10000


func add_floater(position: Vector2, radius: float = 0.0) -> void:
	floaters.push_back(Floater2D.new(position, radius))


func clear_floaters() -> void:
	floaters.clear()


func get_floaters() -> Array[Floater2D]:
	return floaters


func fluid_area_enter(area: FluidArea2D) -> void:
	fluid_area = area


func fluid_area_exit(area: FluidArea2D) -> void:
	if fluid_area == area:
		fluid_area = null
