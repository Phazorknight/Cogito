extends CharacterBody3D
class_name CogitoEnemy

## Emitted when received damage. Used with the HitboxComponent
signal damage_received(damage_value:float)

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


func _ready() -> void:
	current_state = start_state


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


func handle_chasing(_delta: float):
	#Currently just chasing the player. TODO: Change to have a dynamic target.
	chase_target = CogitoSceneManager._current_player_node
	
	look_at(Vector3(chase_target.global_position.x,global_position.y,chase_target.global_position.z))
	
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
			# Move towards patrol point
			look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z))
			move_toward_target(patrol_points[patrol_point_index],patrol_speed)


func move_toward_target(target: Node3D, passed_speed:float):
	if !target: return
	
	nav_agent.set_target_position(target.global_position)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * passed_speed
	move_and_slide()


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
