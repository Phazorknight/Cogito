extends Node

# These will be autofilled by the StateMachine
var Host # is our Character node (parent of StateMachine)
var States # is the StateMachine itself

@export var investigate_speed: float = 2.0
@export var investigation_duration: float = 4.0
@export var look_around_speed: float = 1.0

var investigation_target_pos: Vector3
var is_waiting: bool = false
var investigation_timer: float = 0.0

func _state_enter(args = null):
	CogitoGlobals.debug_log(true, "npc_state_investigate.gd", "Investigate state entered")
	
	if args != null and args is Vector3:
		investigation_target_pos = args
		Host.move_speed = investigate_speed
		Host.navigation_agent_3d.target_position = investigation_target_pos
		is_waiting = false
	else:
		# If no position provided, just return to previous state
		States.load_previous_state()


func _physics_process(delta):
	Host.update_animations(delta)
	
	if is_waiting:
		investigation_timer -= delta
		
		# Optional: Look around behavior here
		# For now, just wait
		
		if investigation_timer <= 0:
			finish_investigation()
		return

	if Host.navigation_agent_3d.is_navigation_finished():
		start_waiting()
		return

	var next_position = Host.navigation_agent_3d.get_next_path_position()
	
	# Gravity
	if not Host.is_on_floor():
		Host.velocity += Host.get_gravity() * delta

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


func start_waiting():
	is_waiting = true
	investigation_timer = investigation_duration
	Host.velocity = Vector3.ZERO
	# Play idle/investigate animation if available
	# Host.animation_tree.set("parameters/UpperBodyState/playback", "idle") 


func finish_investigation():
	CogitoGlobals.debug_log(true, "npc_state_investigate.gd", "Investigation finished. return to previous state.")
	States.load_previous_state()
