extends Node

# These will be autofilled by the StateMachine
var Host # is our Character node (parent of StateMachine)
var States # is the StateMachine itself

@export var move_animation : String = ""
@export var max_distance_from_host : float = 10.0

enum TravelStatus{ SUCCESS, FAILURE, RUNNING, WAITING = 3 }
var current_travel_status : TravelStatus

func _state_enter():
	print(name, " state entered")
	Host.navigation_agent_3d.target_position = pick_destination()
	current_travel_status = TravelStatus.RUNNING


func _state_exit():
	States.save_state_as_previous(self.name,null)


func _physics_process(_delta):
	Host.update_animations(_delta)
	
	match current_travel_status:
		TravelStatus.WAITING:
			# Lerping down the velocity
			Host.velocity.x = move_toward(Host.velocity.x, 0, _delta * Host.move_speed)
			Host.velocity.z = move_toward(Host.velocity.z, 0, _delta * Host.move_speed)
			Host.move_and_slide()
			if Host.velocity.length_squared() == 0:
				current_travel_status = TravelStatus.SUCCESS
			return
			
		TravelStatus.RUNNING:
			_running(_delta)
			
		TravelStatus.SUCCESS: # Ends this state.
			States.goto("idle")
			
		TravelStatus.FAILURE:
			Host.navigation_agent_3d.target_position = pick_destination()
			current_travel_status = TravelStatus.RUNNING

	var look_ahead := Vector3(Host.global_position.x + Host.velocity.x, Host.global_position.y, Host.global_position.z + Host.velocity.z)


func pick_destination():
	var current_position = Host.get_global_position()
	var new_destination = random_position(random_direction())
	return new_destination


func _running(delta: float):
	if Host.navigation_agent_3d.is_navigation_finished():
		current_travel_status =  TravelStatus.WAITING
		
	if not Host.navigation_agent_3d.is_target_reachable():
		current_travel_status =  TravelStatus.FAILURE
		
	move_host_to_next_position(delta)


func move_host_to_next_position(_delta: float) -> void:
	var next_position = Host.navigation_agent_3d.get_next_path_position()
	
	# Add the gravity.
	if not Host.is_on_floor():
		Host.velocity += Host.get_gravity() * _delta

	var direction = Host.global_position.direction_to(next_position)
	var face_direction := Vector3(Host.global_position.x + Host.velocity.x, Host.global_position.y, Host.global_position.z + Host.velocity.z)

	if direction:
		Host.face_direction(face_direction)
		Host.velocity.x = direction.x * Host.move_speed
		Host.velocity.z = direction.z * Host.move_speed
	else:
		Host.velocity.x = move_toward(Host.velocity.x, 0, Host.move_speed)
		Host.velocity.z = move_toward(Host.velocity.z, 0, Host.move_speed)
		
	Host.move_and_slide()


func random_position(direction: Vector3) -> Vector3:
	var target_position : Vector3
	var distance: float = randi_range(1, max_distance_from_host)
	target_position = direction * distance
	return target_position


func random_direction() -> Vector3:
	var dir_x = randf_range(-1,1)
	var dir_z = randf_range(-1,1)
	
	var directional_vector : Vector3 = Vector3(dir_x, 0, dir_z).normalized()
	return directional_vector
