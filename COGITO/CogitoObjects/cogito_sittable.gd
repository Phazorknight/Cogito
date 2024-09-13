@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoSittable.svg")
extends Node3D
class_name CogitoSittable

signal object_state_updated(interaction_text: String) #used to display correct interaction prompts
signal player_sit_down()
signal player_stand_up()

#region Variables
##
@export var is_sat_on_start: bool = false
##Is this Sittable static or a Physics object?
@export var physics_sittable: bool =  false
##Interaction text when Sat Down
@export var interaction_text_when_on : String = "Stand Up"
##Interction text when not Sat Down
@export var interaction_text_when_off : String = "Sit"
##Disables (sibling) Carryable Component if found
@export var disable_carry : bool = true
##Limits horizontal view to the look angle
@export var limit_horizontal_view : bool = true
##Players maximum Horizontal Look angle when Sitting
@export var look_angle: float = 120
##Limit vertical view
@export var limit_vertical_view : bool = true
##Height to lower Sit marker by, to account for the difference between player head and body height
@export var sit_marker_displacement: float = 0.7
##Area in which the Sitable can be interacted with
@export var sit_area_behaviour: SitAreaBehaviour = SitAreaBehaviour.MANUAL
##Where should player be placed on Sittable exit
@export var placement_leave_behaviour: PlacementOnLeave = PlacementOnLeave.ORIGINAL
##Disable interaction while player is in the air
@export var disable_on_jump: bool = true
@export_group("Animation")
##Move the player to the Sit marker location using a Tween
@export var tween_to_location : bool = true
##Make the player look at the look marker. Required for Limited look angles
@export var tween_to_look_marker : bool = true
##Length of time player tweens into seat
@export var tween_duration: float = 0.8
##Time for rotation tween to face Look marker
@export var rotation_tween_duration: float = 0.4
@export_group("Nodes")
##Node used as the Sit marker, Defines Player location when sitting
@export var sit_position_node_path: NodePath
##Node used as the Look marker, Defines centre of vision when sitting
@export var look_marker_node_path: NodePath
##Area in which the Sitable can be interacted with
@export var sit_area_node_path: NodePath
## Node used to place player when Placement leave behaviour tells it to
@export var leave_node_path: NodePath 

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
	AUTO,    ## Attempt to find nearby available location for Player using Navmesh
	TRANSFORM     ## Player is placed at defined Leave node  Make sure this is setup in Nodes section
}

@onready var AudioStream3D = $AudioStreamPlayer3D
@onready var BasicInteraction = $BasicInteraction

var interaction_text : String 
var sit_position_node: Node3D = null
var look_marker_node: Node3D = null
var original_position: Transform3D  
var interaction_nodes : Array[Node]
var carryable_components: Array = [Node]
var player_node: Node3D = null
var player_in_sit_area: bool = false

#endregion

func _ready():
	#find player node
	player_node = CogitoSceneManager._current_player_node
	self.add_to_group("interactable")
	add_to_group("save_object_state")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	
	#find sit position node
	sit_position_node = get_node_or_null(sit_position_node_path)
	if not sit_position_node:
		print("Sit position node not found. Ensure the path is correct.")
	else:
		displace_sit_marker()
		
	# find the look marker node
	look_marker_node = get_node_or_null(look_marker_node_path)
	if not look_marker_node:
		print("Look marker node not found.")	
		
	match sit_area_behaviour:
			SitAreaBehaviour.MANUAL:
				BasicInteraction.is_disabled = true
			SitAreaBehaviour.MANUAL:
				BasicInteraction.is_disabled = true
			SitAreaBehaviour.NONE:
				BasicInteraction.is_disabled = false
	if disable_carry:
		carryable_components = get_sibling_carryable_components()
		
	if is_sat_on_start:
		interact(player_node.player_interaction_component)
		BasicInteraction.is_disabled = false
		

func get_sibling_carryable_components() -> Array:
	var components = []
	var parent = get_parent()
	
	# iterate through sibling nodes and check for CogitoCarryableComponent
	for child in parent.get_children():
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
	interaction_text = interaction_text_when_on
	object_state_updated.emit(interaction_text)
	if enable_on_sit:
		enable_on_sit.disabled = false
	# Disable carryable components if necessary
	if disable_carry:
		for component in carryable_components:
			component.is_disabled = true
	for node in nodes_to_show_when_on:
		node.show()
		
	for node in nodes_to_hide_when_on:
		node.hide()
		
func _stand_up():
	interaction_text = interaction_text_when_off
	object_state_updated.emit(interaction_text)
	if enable_on_sit:
		enable_on_sit.disabled = true
	# Enable carryable components if necessary
	if disable_carry:
		for component in carryable_components:
			component.is_disabled = false
			
	for node in nodes_to_show_when_on:
		node.hide()
	for node in nodes_to_hide_when_on:
		node.show()
			
func switch():
	if player_node.is_sitting:
		_stand_up()
		interaction_text = interaction_text_when_off
		object_state_updated.emit(interaction_text)
	else:
		_sit_down()
		#Update interaction text
		interaction_text = interaction_text_when_on
		object_state_updated.emit(interaction_text)

func _on_sit_area_body_entered(body):
	if body == player_node:
		player_in_sit_area = true
		
		match sit_area_behaviour:
			SitAreaBehaviour.MANUAL:
				BasicInteraction.is_disabled = false
			
			SitAreaBehaviour.AUTO:
				if not player_node.is_sitting:
					interact(player_node.player_interaction_component)
					BasicInteraction.is_disabled = false

			SitAreaBehaviour.NONE:
				BasicInteraction.is_disabled = false

func _on_sit_area_body_exited(body):
	if body == player_node:
		player_in_sit_area = false
		if player_node.is_sitting:
			#don't disable interactable if the players sitting to avoid player getting stuck
			BasicInteraction.is_disabled = false
		else: 
			BasicInteraction.is_disabled = true
			
var interact_cooldown = 0.0

func interact(player_interaction_component):
	# Get the current time from the engine
	var current_time = Time.get_ticks_msec()/ 1000.0

	# If cooldown hasn't passed, return early to prevent spamming
	if current_time < interact_cooldown:
		return
	
	# Reset cooldown to current time + duration
	interact_cooldown = current_time + interact_cooldown_duration
	
	if disable_on_jump == true:
		if player_node.is_in_air:
			return
	
	AudioStream3D.play()
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



