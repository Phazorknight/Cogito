@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoSittable.svg")
extends Node3D
class_name CogitoSittable

signal object_state_updated(interaction_text: String) #used to display correct interaction prompts
signal player_sit_down()
signal player_stand_up()

#region Variables
## Name that will displayed when interacting. Leave blank to hide
@export var display_name : String
##
@export var is_sat_on_start: bool = false
##Is this Sittable static or a Physics object?
@export var physics_sittable: bool =  false
##Interaction text when Sat Down
@export var interaction_text_when_on : String = "Stand Up"
##Interction text when not Sat Down
@export var interaction_text_when_off : String = "Sit"

@export_category("Sittable Behaviour")
##Area in which the Sitable can be interacted with
@export var sit_area_behaviour: SitAreaBehaviour = SitAreaBehaviour.MANUAL
##Where should player be placed on Sittable exit
@export var placement_on_leave: PlacementOnLeave = PlacementOnLeave.ORIGINAL
##Disable interaction while player is in the air
@export var disable_on_jump: bool = true
##Disable interaction while player is in the Crouching
@export var disable_on_crouch: bool = true
##Disables child Carryable Component if found, prevents Carrying sat on Chair
@export var disable_carry : bool = true
##Should the player get ejected from the seat if it falls beyond eject_angle?
@export var eject_on_fall: bool = false
##What angle should the player get ejected from Seat at? Also used to define fallen chair angle, to prevent interaction with fallen chairs
@export var eject_angle: float = 45

@export_group("Vision")
##Players maximum Horizontal Look angle in either direction when Sitting
@export var horizontal_look_angle: float = 120
##Players maximum Vertical Look angle in either direction when Sitting
@export var vertical_look_angle: float = 90
##Height to lower Sit marker by, to account for the difference between player head and body height
@export var sit_marker_displacement: float = 0.7

@export_group("Animation")
##Move the player to the Sit marker location using a Tween
@export var tween_to_location : bool = true
##Make the player look at the look marker. Required for Limited look angles
@export var tween_to_look_marker : bool = true
##Length of time player tweens into seat
@export var tween_duration: float = 0.8
##Time for rotation tween to face Look marker
@export var rotation_tween_duration: float = 0.4
##Name of animation in the Animation player node, to play on enter
@export var animation_on_enter: String 
##Name of animation in the Animation player node, to play on leave
@export var animation_on_leave: String

@export_group("Audio")
@export var sit_sound : AudioStream
@export var stand_sound : AudioStream
@export var sit_pitch : float = 0.5
@export var stand_pitch : float = 0.5

@export_group("Nodes")
##Node used as the Sit marker, Defines Player location when sitting
@export var sit_position_node_path: NodePath
##Node used as the Look marker, Defines centre of vision when sitting
@export var look_marker_node_path: NodePath
##Area in which the Sitable can be interacted with
@export var sit_area_node_path: NodePath
## Node used to place player when Placement leave behaviour tells it to
@export var leave_node_path: NodePath 
##Animation player node
@export var animation_player_node_path: NodePath

@export_group("Interaction")
##Time before player can interact again. To prevent Spam which can cause issues with the player movement
@export var interact_cooldown_duration = 0.4
##Enable this node on sit (useful for enabling collision shapes)
@export var enable_on_sit: Node
## Nodes that will become visible when switch is ON. These will hide again when switch is OFF.
@export var nodes_to_show_when_on : Array[Node]
## Nodes that will become hidden when switch is ON. These will show again when switch is OFF.
@export var nodes_to_hide_when_on : Array[Node]
## Nodes that will have their interact function called when this is used.
@export var objects_call_interact : Array[NodePath]
@export var objects_call_delay : float = 0.0

enum SitAreaBehaviour {
	MANUAL,  ## Player needs to interact manually
	AUTO,    ## Player sits automatically on entry
	NONE     ## Player can interact from outside Sit Area
}

enum PlacementOnLeave {
	ORIGINAL,  ## Player returns to original location
	AUTO,    ## Attempt to find nearby available location for Player using Navmesh - Experimental
	TRANSFORM,     ## Player is placed at defined Leave node  Make sure this is setup in Nodes section
	DISPLACEMENT	## The displacement between player and Sittable is taken on sit down, and used on standup relative to Sittables new location
}

@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var BasicInteraction = $BasicInteraction

var is_occupied: bool = false
var occupant_id: String = "" 
var interaction_text : String 
var sit_position_node: Node3D = null
var look_marker_node: Node3D = null
var animation_player: AnimationPlayer
var original_position: Transform3D  
var interaction_nodes : Array[Node]
var carryable_components: Array = [Node]
var player_node: Node3D = null
var player_in_sit_area: bool = false
var cogito_properties : CogitoProperties = null

var interaction_component_state:bool = false
#endregion


func _ready():
	#find player node
	player_node = CogitoSceneManager._current_player_node
	self.add_to_group("interactable")
	add_to_group("save_object_state")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	interaction_component_state = false # set interaction component to disabled on startup
	#find sit position node
	sit_position_node = get_node_or_null(sit_position_node_path)
	if not sit_position_node:
		CogitoGlobals.debug_log(true, "CogitoSittable", "Sit position node not found. Ensure the path is correct.")
	else:
		displace_sit_marker()
		
	# find the look marker node
	look_marker_node = get_node_or_null(look_marker_node_path)
	if not look_marker_node:
		CogitoGlobals.debug_log(true, "CogitoSittable", "Look marker node not found.")	
	
	#find optional animation player node
	animation_player = get_node_or_null(animation_player_node_path)
	
	match sit_area_behaviour:
			SitAreaBehaviour.MANUAL:
				BasicInteraction.is_disabled = true
			SitAreaBehaviour.MANUAL:
				BasicInteraction.is_disabled = true
			SitAreaBehaviour.NONE:
				BasicInteraction.is_disabled = false
				
	if disable_carry:
		carryable_components = get_child_carryable_components()
		
	if is_sat_on_start:
		interact(player_node.player_interaction_component)
		BasicInteraction.is_disabled = false
	
	find_cogito_properties()


func get_child_carryable_components() -> Array:
	var components = []
	# iterate through child nodes and check for CogitoCarryableComponent
	for child in self.get_children():
		if child is CogitoCarryableComponent:
			components.append(child)
	return components


func displace_sit_marker():
	if sit_position_node:
		# Adjust the sit marker node downward based on sit_marker_displacement
		var adjusted_transform = sit_position_node.transform
		adjusted_transform.origin.y -= sit_marker_displacement
		sit_position_node.transform = adjusted_transform


func _sit_down():
	
	if animation_player:
		animation_player.play(animation_on_enter)
	
	#sit down audio
	audio_stream_player_3d.stream = sit_sound
	audio_stream_player_3d.pitch_scale = sit_pitch
	audio_stream_player_3d.play()
	
	#update interaction text
	interaction_text = interaction_text_when_on
	object_state_updated.emit(interaction_text)
	
	#enable any enable on sit node
	if enable_on_sit:
		enable_on_sit.disabled = false
		
	# Disable carryable components if necessary
	if disable_carry:
		for component in carryable_components:
			component.is_disabled = true
			
	#show any show on sit node		
	for node in nodes_to_show_when_on:
		node.show()
	for node in nodes_to_hide_when_on:
		node.hide()
	
	is_occupied = true


func _stand_up():
	
	if animation_player:
		animation_player.play(animation_on_leave)
	
	#stand up audio
	audio_stream_player_3d.stream = stand_sound
	audio_stream_player_3d.pitch_scale = stand_pitch
	audio_stream_player_3d.play()
	
	#update interaction text
	interaction_text = interaction_text_when_off
	object_state_updated.emit(interaction_text)
	
	#disable any enable_on_sit node
	if enable_on_sit:
		enable_on_sit.disabled = true
		
	# Enable carryable components if necessary
	if disable_carry:
		for component in carryable_components:
			component.is_disabled = false
	
	#hide any show on sit node		
	for node in nodes_to_show_when_on:
		node.hide()
	for node in nodes_to_hide_when_on:
		node.show()
	
	is_occupied = false


func switch():
	if is_occupied:
		_stand_up()
	else:
		_sit_down()


func set_state():
	#On loadet behaviour
	match sit_area_behaviour:
			SitAreaBehaviour.MANUAL:
				BasicInteraction.is_disabled = true
			SitAreaBehaviour.MANUAL:
				BasicInteraction.is_disabled = true
			SitAreaBehaviour.NONE:
				BasicInteraction.is_disabled = false
	
	find_cogito_properties()
	
	#If the saved interaction state is true, override on load to avoid player getting stuck. Can ignore the reverse
	if interaction_component_state == true:
		BasicInteraction.is_disabled = false
		
	if is_occupied:
		_sit_down()
	else:
		_stand_up()


func _on_sit_area_body_entered(body):
	if body == player_node:
		player_in_sit_area = true
		
		match sit_area_behaviour:
			SitAreaBehaviour.MANUAL:
				BasicInteraction.is_disabled = false
				interaction_component_state = true
			
			SitAreaBehaviour.AUTO:
				if not player_node.is_sitting:
					interact(player_node.player_interaction_component)
					BasicInteraction.is_disabled = false
					interaction_component_state = true
			SitAreaBehaviour.NONE:
				BasicInteraction.is_disabled = false
				interaction_component_state = true


func _on_sit_area_body_exited(body):
	if body == player_node:
		player_in_sit_area = false
		if player_node.is_sitting:
			#don't disable interactable if the players sitting to avoid player getting stuck
			interaction_component_state = true
			BasicInteraction.is_disabled = false
		else: 
			BasicInteraction.is_disabled = true
			interaction_component_state = false


func find_cogito_properties():
	var property_nodes = find_children("","CogitoProperties",true) #Grabs all attached property components
	if property_nodes:
		cogito_properties = property_nodes[0]

var interact_cooldown = 0.0


func interact(player_interaction_component):
	
	#Prevent entering fallen chair
	if !is_occupied and _is_fallen():
		player_interaction_component.send_hint(null, "I can't sit there!")
		return
	
	# Get the current time from the engine
	var current_time = Time.get_ticks_msec()/ 1000.0

	# If cooldown hasn't passed, return early to prevent spamming
	if current_time < interact_cooldown:
		return
	
	# Reset cooldown to current time + duration
	interact_cooldown = current_time + interact_cooldown_duration
	
	if disable_on_crouch == true:
		if player_node.is_crouching:
			player_interaction_component.send_hint(null, "I should stand up first")
			return
	
	if disable_on_jump == true:
		if player_node.is_in_air:
			player_interaction_component.send_hint(null, "I should land first")
			return
	
	# If the player is already sitting in a seat, and interacts with that seat then stand
	if player_node.is_sitting and CogitoSceneManager._current_sittable_node == self:
		CogitoSceneManager.emit_signal("stand_requested")
		_stand_up()

	# If the player is already sitting in a seat, and interacts with a different seat then move seat
	elif player_node.is_sitting and CogitoSceneManager._current_sittable_node != self :
		var previous_seat = CogitoSceneManager._current_sittable_node
		previous_seat._stand_up()
		CogitoSceneManager._current_sittable_node = self
		CogitoSceneManager.emit_signal("seat_move_requested", self)
		_sit_down()

	# If the player is not in any seat, then sit down
	elif not player_node.is_sitting:
		CogitoSceneManager._current_sittable_node = self
		CogitoSceneManager.emit_signal("sit_requested", self)
		_sit_down()

	if !objects_call_interact:
		return
	for nodepath in objects_call_interact:
		await get_tree().create_timer(objects_call_delay).timeout
		if nodepath != null:
			var object = get_node(nodepath)
			object.interact(player_interaction_component)


func _is_fallen() -> bool:
	var current_rotation = global_transform.basis.get_euler()
	var pitch_angle = rad_to_deg(abs(current_rotation.x))
	var roll_angle = rad_to_deg(abs(current_rotation.z))
	if pitch_angle > eject_angle or roll_angle > eject_angle:
		return true
	return false


func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"is_occupied" : is_occupied,
		"occupant_id" : occupant_id,
		"physics_sittable" : physics_sittable,
		"interaction_text" : interaction_text,
		"interaction_component_state" : interaction_component_state,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		"global_pos_x" : global_position.x,
		"global_pos_y" : global_position.y,
		"global_pos_z" : global_position.z,
		
	}
	# If the node is a RigidBody3D, then save the physics properties of it
	var rigid_body = find_rigid_body()
	if rigid_body:
		state_dict["linear_velocity_x"] = rigid_body.linear_velocity.x
		state_dict["linear_velocity_y"] = rigid_body.linear_velocity.y
		state_dict["linear_velocity_z"] = rigid_body.linear_velocity.z
		state_dict["angular_velocity_x"] = rigid_body.angular_velocity.x
		state_dict["angular_velocity_y"] = rigid_body.angular_velocity.y
		state_dict["angular_velocity_z"] = rigid_body.angular_velocity.z
	return state_dict
	
	
func find_rigid_body() -> RigidBody3D:
	var current = self
	while current:
		if current is RigidBody3D:
			return current as RigidBody3D
		current = current.get_parent()
	return null
