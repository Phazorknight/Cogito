extends Node

# These will be autofilled by the StateMachine
var Host # is our Character node (parent of StateMachine)
var States # is the StateMachine itself

@export var move_animation : String = ""
@export var waiting_animation : String = ""
@export var patrol_point_wait_time : float = 3.0
@export var patrol_point_threshold : float = 0.4

enum TravelStatus{ SUCCESS, FAILURE, RUNNING, WAITING = 3 }
var current_travel_status : TravelStatus = TravelStatus.WAITING

var patrol_wait_timer : Timer
var patrol_point_index : int = 0


func _enter_tree() -> void:
	patrol_wait_timer = Timer.new()
	patrol_wait_timer.wait_time = patrol_point_wait_time
	patrol_wait_timer.one_shot = true
	patrol_wait_timer.timeout.connect(resume_patrolling)
	add_child(patrol_wait_timer)


func _state_enter():
	print(name, " state entered")
	Host.navigation_agent_3d.target_position = set_next_patrol_point_destination()
	current_travel_status = TravelStatus.RUNNING


func _state_exit():
	States.save_state_as_previous(self.name,null)
	pass


func _physics_process(_delta):
	Host.update_animations(_delta)
	
	match current_travel_status:
		TravelStatus.WAITING:
			# Lerping down the velocity
			Host.velocity.x = move_toward(Host.velocity.x, 0, _delta * Host.move_speed)
			Host.velocity.z = move_toward(Host.velocity.z, 0, _delta * Host.move_speed)
			Host.move_and_slide()
			return
		TravelStatus.RUNNING:
			_running(_delta)
		TravelStatus.SUCCESS:
			# This would end patrolling
			pass
		TravelStatus.FAILURE:
			iterate_patrol_point_index() #Switches to the next patrol point if current one is not reachable.
			Host.navigation_agent_3d.target_position = set_next_patrol_point_destination()
			current_travel_status = TravelStatus.RUNNING


	var look_ahead := Vector3(Host.global_position.x + Host.velocity.x, Host.global_position.y, Host.global_position.z + Host.velocity.z)


func set_next_patrol_point_destination():
	if Host.patrol_path:
		var new_destination = Host.patrol_path.patrol_points[patrol_point_index].global_position
		return new_destination
	else:
		return null


func _running(delta: float):
	if not Host.navigation_agent_3d.is_target_reachable():
		CogitoGlobals.debug_log(true,"NPC State Patrol on Path", "Patrol point at index " + str(patrol_point_index) + " is not reach able. Going to next one.")
		iterate_patrol_point_index() #Switches to the next patrol point if current one is not reachable.
		Host.navigation_agent_3d.target_position = set_next_patrol_point_destination()
	
	if Host.navigation_agent_3d.is_navigation_finished():
		wait_at_patrol_point(delta)
		return
	
	move_host_to_next_position(delta)


func wait_at_patrol_point(_delta: float):
	patrol_wait_timer.start()
	current_travel_status = TravelStatus.WAITING


func resume_patrolling() -> void:
	iterate_patrol_point_index()
	Host.navigation_agent_3d.target_position = set_next_patrol_point_destination()
	current_travel_status = TravelStatus.RUNNING


func iterate_patrol_point_index():
	# Checking to see if we've reached the end of the patrol point list.
	if patrol_point_index == Host.patrol_path.patrol_points.size() - 1:
		# If yes, we're starting over:
		patrol_point_index = 0
	else:
		# If no, we're going to the next point:
		patrol_point_index += 1


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
