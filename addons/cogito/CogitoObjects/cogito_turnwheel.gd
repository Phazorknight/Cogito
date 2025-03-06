@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends AnimatableBody3D

signal object_state_updated(interaction_text : String)

@onready var audio_stream_player_3d = $AudioStreamPlayer3D

## Name that will displayed when interacting. Leave blank to hide
@export var display_name : String
## Define the axis the object will rotate.
@export var rotation_axis : Vector3 = Vector3(1,0,0)
## Rotation speed in radians per second.
@export var rotation_speed : float = 1
## Drag the nodes you want to get triggered in here from your scene hierarchy. Their interact func will be called when hold is complete.
@export var nodes_to_trigger : Array[Node]
## AudioStream to play while holding.
@export var hold_audio_stream : AudioStream

var has_been_turned: bool = false
var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null

func _ready():
	self.add_to_group("save_object_state")
	self.add_to_group("interactable")
	
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	audio_stream_player_3d.stream = hold_audio_stream
	
	for node in interaction_nodes:
		if node and node.has_signal("is_being_held"):
			node.is_being_held.connect(_is_being_turned) 


func _is_being_turned(_time_remaining:float):
	if !audio_stream_player_3d.playing:
		audio_stream_player_3d.play()
		
	if has_been_turned:
		self.rotate_object_local(rotation_axis * -1,rotation_speed)
	else:
		self.rotate_object_local(rotation_axis,rotation_speed)
	

func interact(_player_interaction_component):
	audio_stream_player_3d.stop()
	has_been_turned = !has_been_turned
	CogitoGlobals.debug_log(true,"cogito_turnwheel.gd", "Turnwheel has been turned: " + str(has_been_turned) )
	for node in nodes_to_trigger:
		node.interact(null)


func set_state():
	pass

func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"has_been_turned" : has_been_turned,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
