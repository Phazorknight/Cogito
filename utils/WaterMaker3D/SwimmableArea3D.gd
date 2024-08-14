extends Area3D

@export var max_velocity : float = 10.0  # Maximum allowed velocity

var submerged_bodies : Array[RigidBody3D] = []

func _on_body_entered(body):
	if body is CogitoObject:
		body.submerged = true
		submerged_bodies.append(body)
		body.axis_lock_angular_y = true
		# No initial impulse; we use continuous forces in _physics_process

func _physics_process(delta):
	for body in submerged_bodies:
		var carryable = body.find_child("%CarryableComponent")
		if carryable and carryable.is_being_carried:
			continue  # Skip if being carried
		_apply_water_physics(body)
		_cap_velocity(body)

func _apply_water_physics(body : RigidBody3D):
	var buoyancy_force : Vector3
	var gravity_force : Vector3 = Vector3.DOWN * body.mass * 9.8  # Gravity force

	if body.can_float:
		# Buoyancy force for floating objects
		buoyancy_force = Vector3.UP * body.buoyancy
		body.apply_force(buoyancy_force, body.global_transform.origin)
		# Apply gravity force
		body.apply_force(gravity_force * 5, body.global_transform.origin)
		print(body.angular_velocity)
		# Lock rotation while in water
		body.angular_velocity = Vector3.ZERO
	else:
		# Buoyancy force for sinking objects
		if body.mass <= 0.5:
			var sinking_force = Vector3.UP * (1.0 - body.mass) * 5.0  # Reduced force for sinking
			body.apply_force(sinking_force, body.position)
	
	# Apply damping to reduce excessive movement
	body.linear_velocity = body.linear_velocity.lerp(Vector3.ZERO, 0.2)

func _cap_velocity(body : RigidBody3D):
	if body.linear_velocity.length() > max_velocity:
		body.linear_velocity = body.linear_velocity.normalized() * max_velocity

func _on_body_exited(body):
	if body is CogitoObject:
		body.submerged = false
		submerged_bodies.erase(body)
		_cap_velocity(body)  # Ensure velocity is capped on exit
