extends CharacterBody3D
class_name CogitoEnemy

## Emitted when received damage. Used with the HitboxComponent
signal damage_received(damage_value:float)

# COGITO system variables
var cogito_properties : CogitoProperties = null
var properties : int

# ENEMY specific variables
var current_state : EnemyState  #State for simple state machine
var is_waiting : bool = false
var patrol_point_index: int = 0 #Patrol point for patrolling
var chase_target : Node3D = null #Target for chasing
var attack_cooldown : float = 0 #Value used for attack frequency

enum EnemyState{
	IDLE,
	PATROLLING,
	AWARE,
	CHASING,
	DEAD
}

## If the target is within this range, the enemy attacks
@export var attack_range: float = 1.0
## How much health the target loses when hit.
@export var attack_damage: int = 10
## How often the player can attack (eg. 2.0 = once every 2 seconds)
@export var attack_interval: float = 2.0
## The stagger/bounce back strength of the attack
@export var attack_stagger: float = 8.0
## The state the enemy starts in.
@export var start_state : EnemyState
## The enemy speed when chasing.
@export var chase_speed: float = 5.0
## The enemy speed when patrolling.
@export var patrol_speed: float = 3.0
## List of patrol points which the enemy will move to in order.
@export var patrol_points : Array[Node3D]
## Distance threshold in which the enemy will stop (to make patrolling smoother)
@export var patrol_point_threshold : float = 0.4
## Time the enemy will wait at each patrol point
@export var patrol_point_wait_time : float = 2.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D


#FootstepPlayer variables
@export_group ("Footstep Player")
##Determines if Footsteps are enabled for NPC
@export var footsteps_enabled: bool = true
##Sets Walk volume in dB
@export var walk_volume_db: float = -12
##Sets Walk volume in dB
@export var sprint_volume_db: float = -4
##Determines the footstep occurence frequency for Walking
@export var WIGGLE_ON_WALKING_SPEED: float = 12.0
##Determines the footstep occurence frequency for Sprinting
@export var WIGGLE_ON_SPRINTING_SPEED: float = 16.0

@onready var footstep_player = $FootstepPlayer

var can_play_footstep: bool = true
var wiggle_vector : Vector2 = Vector2.ZERO
var wiggle_index : float = 0.0

func _ready() -> void:
	self.add_to_group("Persist") #Adding object to group for persistence
	find_cogito_properties()
	
	current_state = start_state


func find_cogito_properties():
	var property_nodes = find_children("","CogitoProperties",true) #Grabs all attached property components
	if property_nodes:
		cogito_properties = property_nodes[0]
		#print(name, ": cogito_properties set to ", cogito_properties)


func _physics_process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	match current_state:
		EnemyState.PATROLLING:
			handle_patrolling(delta)
		EnemyState.AWARE:
			pass
		EnemyState.CHASING:
			handle_chasing(delta)
		EnemyState.IDLE:
			pass
		EnemyState.DEAD:
			pass
	
	if footsteps_enabled:
		npc_footsteps(delta)
	
func handle_chasing(_delta: float):
	#Currently just chasing the player. TODO: Change to have a dynamic target.
	chase_target = CogitoSceneManager._current_player_node
	
	# This is basically a lerped look-at
	_look_at_target_interpolated(chase_target.global_position)
	
	if _target_in_range() and attack_cooldown <= 0:
		attack(chase_target)
	
	move_toward_target(chase_target,chase_speed)


func handle_patrolling(_delta: float):
	if !is_waiting:
		if global_position.distance_to(patrol_points[patrol_point_index].global_position) < patrol_point_threshold:
			is_waiting = true
			await get_tree().create_timer(patrol_point_wait_time).timeout
			# Checking to see if we've reached the end of the patrol point list.
			if patrol_point_index == patrol_points.size() - 1:
				# If yes, we're starting over.
				patrol_point_index = 0
			else:
				# If no, we're going to the next point:
				patrol_point_index += 1
			is_waiting = false
		
		else:
			var look_ahead := Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z)
			_look_at_target_interpolated(look_ahead)
			
			# Move towards patrol point
			move_toward_target(patrol_points[patrol_point_index],patrol_speed)


func move_toward_target(target: Node3D, passed_speed:float):
	if !target: return
	
	nav_agent.set_target_position(target.global_position)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * passed_speed
	move_and_slide()


func _look_at_target_interpolated(look_direction: Vector3) -> void:
	var look_at_target = global_position.direction_to(look_direction)
	var target_basis= Basis.looking_at(look_at_target)
	basis = basis.slerp(target_basis, 0.2)


func _target_in_range() -> bool:
	return global_position.distance_to(chase_target.global_position) < attack_range


func attack(target: Node3D):
	attack_cooldown = attack_interval
	print("Enemy attacks!")
	var dir = global_position.direction_to(target.global_position)
	target.velocity += dir * attack_stagger
	if target is CogitoPlayer:
		target.decrease_attribute("health", attack_damage)


func switch_to_patrolling():
	current_state = EnemyState.PATROLLING


func switch_to_aware():
	current_state = EnemyState.AWARE


func switch_to_chasing():
	current_state = EnemyState.CHASING


# Future method to set object state when a scene state file is loaded.
func set_state():	
	#TODO: Find a way to possibly save health of health attribute.
	find_cogito_properties()
	pass

# NPC Footstep system, adapted from players
func npc_footsteps(delta):
	#Need to check if not waiting, as Velocity.length is unreliable here
	if not is_waiting:
		
		# Sprinting Case, so using defined number from Chase speed.
		# rounded velocity.length used due to tiny speed fluctuations
		if round(velocity.length()) >= chase_speed:
			wiggle_vector.y = sin(wiggle_index)
			wiggle_index += WIGGLE_ON_SPRINTING_SPEED * delta
			
			if can_play_footstep and wiggle_vector.y > 0.9:
				footstep_player.volume_db = sprint_volume_db
				footstep_player._play_interaction("footstep")
				can_play_footstep = false
			
			if !can_play_footstep and wiggle_vector.y < 0.9:
				can_play_footstep = true
		
		# Walking Case, so only checks if the NPC has any speed before playing sound
		elif velocity.length() >= 0.2:
			wiggle_vector.y = sin(wiggle_index)
			wiggle_index += WIGGLE_ON_WALKING_SPEED * delta
			
			if can_play_footstep and wiggle_vector.y > 0.9:
				footstep_player.volume_db = walk_volume_db
				footstep_player._play_interaction("footstep")
				can_play_footstep = false
			
			if !can_play_footstep and wiggle_vector.y < 0.9:
				can_play_footstep = true



# Function to handle persistence and saving
func save():
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return node_data


func _on_body_entered(body: Node) -> void:
	# Using this check to only call interactions on other Cogito Objects. #TODO: could be a better check...
	if body.has_method("save") and cogito_properties:
		cogito_properties.start_reaction_threshold_timer(body)


func _on_body_exited(body: Node) -> void:
	# Using this check to only call interactions on other Cogito Objects. #TODO: could be a better check...
	if body.has_method("save") and cogito_properties:
		cogito_properties.check_for_reaction_timer_interrupt(body)

