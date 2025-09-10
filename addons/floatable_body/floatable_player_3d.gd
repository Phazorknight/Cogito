extends CharacterBody3D
class_name FloatablePlayer3D

@export var mass := 1.0
@export var fluid_damp := 4.0
@export var move_speed := 10.0
@export var rotate_speed := 10.0
@onready var fluid_interactor := FluidInteractor3D.new()


func _ready():
	for owner_id in get_shape_owners():
		var collision = shape_owner_get_owner(owner_id)
		if collision is CollisionShape3D:
			fluid_interactor.add_collision_shape(collision)


func _physics_process(delta: float) -> void:
	fluid_interactor.process(global_transform, mass)
	
	if not fluid_interactor.float_force.is_zero_approx():
		# Bouyancy
		velocity += fluid_interactor.float_force * delta
		# Damping
		velocity += -velocity * fluid_damp * delta

	# Gravity
	velocity += Vector3(0.0, -9.8, 0.0) * delta
	
	var camera = get_viewport().get_camera_3d()
	var move_direction := Vector3.ZERO
	if Input.is_action_pressed("ui_left"):
		move_direction -= camera.basis.x
	if Input.is_action_pressed("ui_right"):
		move_direction += camera.basis.x
	if Input.is_action_pressed("ui_up"):
		move_direction -= camera.basis.z
	if Input.is_action_pressed("ui_down"):
		move_direction += camera.basis.z
	if Input.is_action_just_pressed("ui_accept"):
		velocity += Vector3.UP * 5
	
	if not move_direction.is_zero_approx():
		move_direction.y = 0.0
		move_direction = move_direction.normalized()
		velocity += move_direction * move_speed * delta
		quaternion = quaternion.slerp(Quaternion(Vector3.FORWARD, move_direction), rotate_speed * delta)

	move_and_slide()


func fluid_area_enter(area: FluidArea3D) -> void:
	fluid_interactor.fluid_area_enter(area)


func fluid_area_exit(area: FluidArea3D) -> void:
	fluid_interactor.fluid_area_exit(area)
