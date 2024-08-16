extends Area3D
class_name FluidArea3D

@export var density: float = 100.0
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
				var extent: Vector3 = shape.size * 0.5
				surface_height += (collision.transform * extent).y

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

const WATER_SPLASH = preload("res://game/objects/water_splash.tscn")

var splash_cooldown: float = 2000  # Cooldown in milliseconds
var last_splash_time: Dictionary = {}

func _on_body_entered(body: PhysicsBody3D):
	if body is PhysicsBody3D:
		var current_time = Time.get_ticks_msec()
		var body_id = body.get_instance_id()

		# Check if the body is allowed to make a splash
		if body_id in last_splash_time:
			var time_since_last_splash = current_time - last_splash_time[body_id]
			if time_since_last_splash < splash_cooldown:
				return  # Skip the splash if cooldown hasn't passed

		# Create splash and set the position to the water surface
		var splash_instance = WATER_SPLASH.instantiate()
		add_child(splash_instance)
		splash_instance.global_position = Vector3(body.global_position.x, body.global_position.y, body.global_position.z)
		
		print(splash_instance.global_position.y, "/", body.global_position.y,".  Surface Height: ", surface_height)
		# Update last splash time for this body
		last_splash_time[body_id] = current_time
		body_enter(body)



func _on_body_exited(body):
	if body is PhysicsBody3D:
		body_exit(body)
