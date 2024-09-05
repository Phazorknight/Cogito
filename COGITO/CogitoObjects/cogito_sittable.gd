@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoSittable.svg")
extends Node3D
class_name CogitoSittable

signal object_state_updated(interaction_text: String) #used to display correct interaction prompts

##Path to node used as the Sit marker
@export var sit_position_node_path: NodePath  
@export var tween_duration: float = 1.0
##Interaction text when Sat Down
@export var interaction_text_when_on : String = "Stand Up"
##Interction text when not Sat Down
@export var interaction_text_when_off : String = "Sit"
##Disables (sibling) Carryable Component if found
@export var disable_carry : bool = true

var interaction_text : String 
var player_node: Node3D = null
var sit_position_node: Node3D = null
var is_player_sitting: bool = false
var original_position: Transform3D  
var interaction_nodes : Array[Node]
var carryable_components: Array = [Node]

func _ready():
	#find player node
	player_node = CogitoSceneManager._current_player_node
	
	self.add_to_group("interactable")
	add_to_group("save_object_state")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	
	#find sit position node
	sit_position_node = get_node(sit_position_node_path)
	if not sit_position_node:
		print("Sit position node not found. Ensure the path is correct.")
		
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
	
	
func _sit_down():
	player_node = CogitoSceneManager._current_player_node
	
	if player_node:
		
		# Store original position before sitting, used for standing up
		original_position = player_node.global_transform
		
		# Temporarily disable physics interactions
		player_node.set_physics_process(false)
		
		# Tween the player to the sit position
		var tween = create_tween()
		tween.tween_property(player_node, "global_transform", sit_position_node.global_transform, tween_duration)
		tween.tween_callback(Callable(self, "_on_tween_finished"))
		is_player_sitting = true
		
		if disable_carry:
			for component in carryable_components:
				component.is_disabled = true

func _on_tween_finished():
	player_node.global_transform = sit_position_node.global_transform
	player_node.set_physics_process(true)
	player_node.is_sitting = true

func _stand_up():
	if is_player_sitting and player_node:
		is_player_sitting = false
		player_node.is_sitting = false
		
		# Tween the player back to the original position
		var tween = create_tween()
		tween.tween_property(player_node, "global_transform", original_position, tween_duration)
		tween.tween_callback(Callable(self, "_on_stand_up_finished"))
		
		if disable_carry:
			for component in carryable_components:
				component.is_disabled = false

func _on_stand_up_finished():
	player_node.is_sitting = false  

func switch():
	if is_player_sitting:
		_stand_up()
		interaction_text = interaction_text_when_off
		object_state_updated.emit(interaction_text)
	else:
		_sit_down()
		#Update interaction text
		interaction_text = interaction_text_when_on
		object_state_updated.emit(interaction_text)
		
func interact(player_interaction_component):
	switch()
