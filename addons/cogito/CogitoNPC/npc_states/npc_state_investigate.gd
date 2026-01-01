extends Node

# These will be autofilled by the StateMachine
var Host # is our Character node (parent of StateMachine)
var States # is the StateMachine itself

signal investigation_complete

enum InvestigateStatus{ OBSERVING, MOVING_TO_LOCATION, INVESTIGATING, COMPLETE = 3 }
var current_investigate_status : InvestigateStatus = InvestigateStatus.OBSERVING

@export var investigate_animation : String = "alert"
@export var observe_duration : float = 2.0
@export var investigation_distance : float = 15.0
@export var npc_group_distance : float = 8.0
@export var investigation_timeout : float = 15.0
@export var move_speed_multiplier : float = 0.8

var investigate_location : Vector3
var observe_timer : Timer
var investigation_timer : Timer
var nearby_npcs : Array = []
var host_animation_statemachine


func _enter_tree() -> void:
	observe_timer = Timer.new()
	observe_timer.wait_time = observe_duration
	observe_timer.one_shot = true
	observe_timer.timeout.connect(_on_observe_timer_timeout)
	add_child(observe_timer)
	
	investigation_timer = Timer.new()
	investigation_timer.wait_time = investigation_timeout
	investigation_timer.one_shot = true
	investigation_timer.timeout.connect(_on_investigation_timeout)
	add_child(investigation_timer)


func _state_enter():
	CogitoGlobals.debug_log(true, "npc_state_investigate.gd", name + " state entered")
	
	# Get the location to investigate from Host
	if Host.has_meta("investigate_location"):
		investigate_location = Host.get_meta("investigate_location")
	else:
		investigate_location = Host.global_position + Host.global_transform.basis.z * investigation_distance
	
	host_animation_statemachine = Host.animation_tree.get("parameters/UpperBodyState/playback")
	
	# Start in observing status
	current_investigate_status = InvestigateStatus.OBSERVING
	
	# Switch to alert animation
	if host_animation_statemachine and investigate_animation != "":
		host_animation_statemachine.travel(investigate_animation)
	
	# Start observing timer
	observe_timer.start()
	investigation_timer.start()
	
	# Call nearby NPCs to investigate
	_call_nearby_npcs()


func _state_exit():
	States.save_state_as_previous(self.name, null)
	observe_timer.stop()
	investigation_timer.stop()


func _physics_process(_delta):
	Host.update_animations(_delta)
	
	match current_investigate_status:
		InvestigateStatus.OBSERVING:
			# Stay in place while observing
			Host.velocity.x = move_toward(Host.velocity.x, 0, _delta * Host.move_speed)
			Host.velocity.z = move_toward(Host.velocity.z, 0, _delta * Host.move_speed)
			Host.face_direction(investigate_location)
			Host.move_and_slide()
			
		InvestigateStatus.MOVING_TO_LOCATION:
			_moving_to_location(_delta)
			
		InvestigateStatus.INVESTIGATING:
			# Stay in place while investigating
			Host.velocity.x = move_toward(Host.velocity.x, 0, _delta * Host.move_speed)
			Host.velocity.z = move_toward(Host.velocity.z, 0, _delta * Host.move_speed)
			Host.face_direction(investigate_location)
			Host.move_and_slide()
			
		InvestigateStatus.COMPLETE:
			investigation_complete.emit()
			States.load_previous_state()


func _moving_to_location(_delta: float):
	# Set navigation target
	Host.navigation_agent_3d.target_position = investigate_location
	
	# Check if reached the investigation location
	var distance_to_target = Host.global_position.distance_to(investigate_location)
	if distance_to_target <= 1.5:
		current_investigate_status = InvestigateStatus.INVESTIGATING
		return
	
	# Move towards the location
	if Host.navigation_agent_3d.is_navigation_finished():
		current_investigate_status = InvestigateStatus.INVESTIGATING
		return
	
	var next_position = Host.navigation_agent_3d.get_next_path_position()
	
	# Add gravity
	if not Host.is_on_floor():
		Host.velocity += Host.get_gravity() * _delta
	
	var direction = Host.global_position.direction_to(next_position)
	
	if direction:
		Host.face_direction(next_position)
		Host.velocity.x = direction.x * Host.move_speed * move_speed_multiplier
		Host.velocity.z = direction.z * Host.move_speed * move_speed_multiplier
	else:
		Host.velocity.x = move_toward(Host.velocity.x, 0, Host.move_speed)
		Host.velocity.z = move_toward(Host.velocity.z, 0, Host.move_speed)
	
	Host.move_and_slide()


func _on_observe_timer_timeout():
	# After observing, start moving towards the location
	if current_investigate_status == InvestigateStatus.OBSERVING:
		current_investigate_status = InvestigateStatus.MOVING_TO_LOCATION
		CogitoGlobals.debug_log(true, "npc_state_investigate.gd", name + " moving to investigation location")


func _on_investigation_timeout():
	# Investigation timeout, return to previous state
	if current_investigate_status != InvestigateStatus.COMPLETE:
		CogitoGlobals.debug_log(true, "npc_state_investigate.gd", name + " investigation timeout, returning to previous state")
		current_investigate_status = InvestigateStatus.COMPLETE


func _call_nearby_npcs():
	# Find all NPCs in the scene
	var all_npcs = get_tree().get_nodes_in_group("npc")
	
	for npc in all_npcs:
		if npc == Host:
			continue
		
		var distance_to_npc = Host.global_position.distance_to(npc.global_position)
		
		# If NPC is close enough, call them to investigate
		if distance_to_npc <= npc_group_distance:
			_send_investigate_signal(npc)


func _send_investigate_signal(npc: Node):
	# Send signal or command to nearby NPC to investigate
	if npc.has_method("set_investigate_target"):
		npc.set_investigate_target(investigate_location)
	elif npc.has_meta("state_machine"):
		var state_machine = npc.get_meta("state_machine")
		if state_machine and state_machine.has("investigate"):
			npc.set_meta("investigate_location", investigate_location)
			state_machine.goto("investigate")
