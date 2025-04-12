extends Node

# These will be autofilled by the StateMachine
var Host # is our Character node (parent of StateMachine)
var States # is the StateMachine itself

signal chase_ended

enum ChaseStatus{ CAUGHT, LOST, CHASING, WAITING = 3 }
var current_chase_status : ChaseStatus
var chase_target : Node3D = null

@export var target_action_distance : float = 1.0
@export var action_when_caught : String = "attack"
## If the NPC navigation agent can't reach the chase target for this amount of time (in sec), they'll return to their previous state.
@export var giveup_chase_time : float = 10.0
@export var face_target_while_waiting : bool = true

@export_group("Animation Settings")
@export var chase_stance : String = ""
@export var neutral_stance : String = ""

var chase_wait_timer : Timer
var host_animation_statemachine
var state_before_chase : String


func _enter_tree() -> void:
	chase_wait_timer = Timer.new()
	chase_wait_timer.wait_time = giveup_chase_time
	chase_wait_timer.one_shot = true
	chase_wait_timer.timeout.connect(stop_chasing)
	add_child(chase_wait_timer)


func _state_enter():
	chase_target = Host.attention_target
	host_animation_statemachine = Host.animation_tree.get("parameters/UpperBodyState/playback")
	
	if !chase_target:
		CogitoGlobals.debug_log(true,"npc_state_chase.gd", "Chase target was null. Returning to state = " + States.previous_state)
		States.load_previous_state()
	else:
		host_animation_statemachine.travel(chase_stance)
		Host.move_speed = Host.sprint_speed
		current_chase_status = ChaseStatus.CHASING


func _state_exit():
	chase_target = null


func _physics_process(_delta):
	Host.update_animations(_delta)
	
	match current_chase_status:
		ChaseStatus.WAITING:
			# Lerping down the velocity
			Host.velocity.x = move_toward(Host.velocity.x, 0, _delta * Host.move_speed)
			Host.velocity.z = move_toward(Host.velocity.z, 0, _delta * Host.move_speed)
			Host.move_and_slide()

			if face_target_while_waiting:
				Host.face_direction(chase_target.global_position)
			
			# If chase target becomes reachable again, the chase is resumed.
			Host.navigation_agent_3d.target_position = chase_target.global_position
			if Host.navigation_agent_3d.is_target_reachable():
				chase_wait_timer.stop() 
				current_chase_status = ChaseStatus.CHASING
				
			return
			
		ChaseStatus.CHASING:
			_running(_delta)
			
		ChaseStatus.CAUGHT:
			States.goto(action_when_caught)
			
		ChaseStatus.LOST: # Ends this state.
			host_animation_statemachine.travel(neutral_stance)
			chase_ended.emit()
			CogitoGlobals.debug_log(true,"npc_state_chase.gd", "ChaseStatus LOST, going to state = " + States.previous_state)
			States.load_previous_state()


	var look_ahead := Vector3(Host.global_position.x + Host.velocity.x, Host.global_position.y, Host.global_position.z + Host.velocity.z)


func _running(delta: float):
	Host.navigation_agent_3d.target_position = chase_target.global_position
	var disance_to_target = Host.global_position.distance_to(chase_target.global_position)

	if disance_to_target <= target_action_distance:
		current_chase_status =  ChaseStatus.CAUGHT
		
	if not Host.navigation_agent_3d.is_target_reachable():
		start_waiting(delta)
		
	move_host_to_next_position(delta)


## Call this to abort the chase. Switches status to lost target and goes to previous state.
func stop_chasing() -> void:
	#Switch back to walk_speed
	Host.move_speed = Host.walk_speed
	current_chase_status = ChaseStatus.LOST


## Gets called when chase_target can't be reached via nav agent.
func start_waiting(_delta: float):
	chase_wait_timer.start()
	current_chase_status = ChaseStatus.WAITING


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
