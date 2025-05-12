extends CharacterBody3D
class_name CogitoNPC

## Emitted when received damage. Used with the HitboxComponent
signal damage_received(damage_value:float)
signal object_exits_tree()

#region Cogito Interaction variables needed
@export var cogito_name : String = self.name
## Name that will displayed when interacting. Leave blank to hide
@export var display_name : String

var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var properties : int
#endregion

@export var patrol_path : CogitoPatrolPath

var attention_target : Node3D

@export_group("Movement")
var move_speed : float = 2
@export var walk_speed : float = 2
@export var sprint_speed : float = 4
@export var acceleration : float = 10.0
@export var rotation_speed : float = 0.2

var knockback_force: Vector3 = Vector3.ZERO
var knockback_timer: float = 0.0
@export var knockback_duration: float = 0.5
@export var knockback_strength: float = 10.0

var last_direction

@export_group("Head LookAt")
@export var neck : Node3D
@export var look_object : Node3D
@export var look_at_offset : Vector3 = Vector3.ZERO
@export var skeleton : Skeleton3D
@export var skeleton_neck_bone: String
var new_rotation
var bone_smooth_rotation = 0.0

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

var can_play_footstep: bool = true
var wiggle_vector : Vector2 = Vector2.ZERO
var wiggle_index : float = 0.0

@onready var footstep_player = $FootstepPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var velocity_debug_shape: MeshInstance3D = $VelocityDebugShape

# NPC State related vars
@onready var npc_state_machine: Node = $NPC_State_Machine
var patrol_path_nodepath : NodePath
var saved_enemy_state : String


func _ready():
	self.add_to_group("interactable")
	self.add_to_group("Persist") #Adding object to group for persistence
	find_interaction_nodes()
	find_cogito_properties()


func find_interaction_nodes():
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components


func find_cogito_properties():
	var property_nodes = find_children("","CogitoProperties",true) #Grabs all attached property components
	if property_nodes:
		cogito_properties = property_nodes[0]


func _process(delta: float) -> void:
	if look_object:
		head_lock_at(delta)


func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_force
		knockback_force = lerp(knockback_force, Vector3.ZERO, delta * 5)
		move_and_slide()
		return
	
	if footsteps_enabled:
		npc_footsteps(delta)
	
	#move_and_slide()


func update_animations(_delta: float):
	var relative_velocity = self.global_basis.inverse() * ((self.velocity * Vector3(1,0,1)) / sprint_speed)
	var rel_velocity_xz = Vector2(relative_velocity.x, -relative_velocity.z)
	
	velocity_debug_shape.position = relative_velocity
	
	#print("NPC : update_animations: velocity=", velocity, ". relative_velocity=", relative_velocity, ". rel_velocity_xz=",rel_velocity_xz)
	if rel_velocity_xz.length_squared() > 0:
		animation_tree.set("parameters/Movement/blend_position", rel_velocity_xz)
	else:
		animation_tree.set("parameters/Movement/blend_position", 0)
	

func set_upper_body_state(state_name: String):
	var upper_body_state_machine = animation_tree.get("parameters/UpperBodyState/playback")
	upper_body_state_machine.travel(state_name)


func face_direction(face_direction: Vector3) -> void:
	var face_at_target = global_position.direction_to(face_direction)
	var face_at_target_xz := Vector3(face_at_target.x, 0, face_at_target.z)
	if face_at_target_xz != Vector3.ZERO:
		var target_basis = Basis.looking_at(face_at_target_xz, Vector3.UP, false)
		basis = basis.slerp(target_basis, rotation_speed)


func head_lock_at(_delta:float) -> void:
	var neck_bone = skeleton.find_bone(skeleton_neck_bone)
	neck.look_at(look_object.global_position + look_at_offset, Vector3.UP, true)
	
	var marker_rotation_deg = neck.rotation_degrees
	marker_rotation_deg.x = clamp(marker_rotation_deg.x, -90, 90)
	marker_rotation_deg.y = clamp(marker_rotation_deg.y, -45, 45)
	
	bone_smooth_rotation = lerp_angle(bone_smooth_rotation, deg_to_rad(marker_rotation_deg.y), 3 * _delta)
	
	new_rotation = Quaternion.from_euler(Vector3(deg_to_rad(marker_rotation_deg.x), deg_to_rad(marker_rotation_deg.y), 0))
	skeleton.set_bone_pose_rotation(neck_bone, new_rotation)



# NPC Footstep system, adapted from players
func npc_footsteps(delta):
	# Sprinting Case, so using defined number from Chase speed.
	# rounded velocity.length used due to tiny speed fluctuations
	
	if round(velocity.length()) >= sprint_speed:
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


func apply_knockback(direction: Vector3):
	knockback_force = direction.normalized() * knockback_strength
	knockback_timer = knockback_duration


# Method to set object state when a scene state file is loaded.
func set_state():	
	#TODO: Find a way to possibly save health of health attribute.
	find_cogito_properties()
	load_patrol_points()
	npc_state_machine.goto(saved_enemy_state)

	
# Function to handle persistence and saving
func save():
	if patrol_path:
		patrol_path_nodepath = patrol_path.get_path()
		
	saved_enemy_state = npc_state_machine.current
	
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		"patrol_path_nodepath" : patrol_path_nodepath,
		"saved_enemy_state" : saved_enemy_state,
  		
	}
	return node_data


func load_patrol_points():
	if patrol_path_nodepath:
		CogitoGlobals.debug_log(true,"cogito_basic_enemy.gd","Loading patrol path: " + str(patrol_path_nodepath))
		patrol_path = get_node(patrol_path_nodepath)



func _on_hitbox_component_got_hit() -> void:
	animation_tree.set("parameters/Transition/transition_request","hit")


func _on_security_camera_object_detected(object: Node3D) -> void:
	attention_target = object
