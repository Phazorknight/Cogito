@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoSittable.svg")
extends Node3D
class_name CogitoSittable

signal object_state_updated(interaction_text: String) #used to display correct interaction prompts
signal player_sit_down()
signal player_stand_up()

#region Variables

##Node used as the Sit marker, Defines Player location when sitting
@export var sit_position_node_path: NodePath
##Node used as the Look marker, Defines centre of vision when sitting
@export var look_marker_node_path: NodePath
##Length of time player tweens into seat
@export var tween_duration: float = 1.0
##Interaction text when Sat Down
@export var interaction_text_when_on : String = "Stand Up"
##Interction text when not Sat Down
@export var interaction_text_when_off : String = "Sit"
##Disables (sibling) Carryable Component if found
@export var disable_carry : bool = true
##Players maximum Look angle when Sitting
@export var look_angle: float = 120
##Height amount to lower Sit marker by
@export var sit_marker_displacement: float = 0.5

@onready var AudioStream3D = $AudioStreamPlayer3D

var interaction_text : String 
var sit_position_node: Node3D = null
var look_marker_node: Node3D = null
var original_position: Transform3D  
var interaction_nodes : Array[Node]
var carryable_components: Array = [Node]
var player_node: Node3D = null

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
		
	if disable_carry:
		carryable_components = get_sibling_carryable_components()

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
	
	# Disable carryable components if necessary
	if disable_carry:
		for component in carryable_components:
			component.is_disabled = true

func _stand_up():
	interaction_text = interaction_text_when_off
	object_state_updated.emit(interaction_text)
	
	# Enable carryable components if necessary
	if disable_carry:
		for component in carryable_components:
			component.is_disabled = false
	
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
		
func interact(player_interaction_component):
	
	AudioStream3D.play()
	# If the player is already sitting in a seat, and interacts with that seat then stand
	if player_node.is_sitting and CogitoSceneManager._current_sittable_node == self:
		CogitoSceneManager.emit_signal("stand_requested")
		_stand_up()

		
	# If the player is already sitting in a seat, and interacts with a different seat then move seat
	elif player_node.is_sitting and CogitoSceneManager._current_sittable_node != self :
		CogitoSceneManager._current_sittable_node = self
		CogitoSceneManager.emit_signal("seat_move_requested", self)
		_sit_down()

	# If the player is not in any seat, then sit down
	elif not player_node.is_sitting:
		CogitoSceneManager._current_sittable_node = self
		CogitoSceneManager.emit_signal("sit_requested", self)
		_sit_down()

