@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoObject.svg")
class_name CogitoPressureplate
extends Node3D

signal object_state_updated(interaction_text: String) #used to display correct interaction prompts
signal plate_activated()
signal plate_deactivated()
signal damage_received(damage_value:float)

@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var base: StaticBody3D = $Base

## Sets this pressure plate as active (can be activated etc)
@export var is_usable : bool = true
## Toggle if switchable can be interacted with repeatedly or not.
@export var allows_repeated_interaction : bool = true
## Sound that plays when weighed down.
@export var activation_sound : AudioStream

## Nodes that will have their interact function called when this switch is used.
@export var objects_call_interact : Array[NodePath]
@export var objects_call_delay : float = 0.0

@export_group("Plate settings")
@export var plate_node : Node3D
@export var unweighted_plate_position : Vector3
@export var weighted_down_plate_position : Vector3
@export var tween_time : float = .3

var is_activated : bool = false
var cogito_properties : CogitoProperties = null
var player_interaction_component : PlayerInteractionComponent


func _ready():
	add_to_group("save_object_state")
	audio_stream_player_3d.stream = activation_sound


func weigh_down():
	audio_stream_player_3d.play()
	
	is_activated = true
	plate_activated.emit()
	
	if !objects_call_interact:
		return
	for nodepath in objects_call_interact:
		await get_tree().create_timer(objects_call_delay).timeout
		if nodepath != null:
			var object = get_node(nodepath)
			object.interact(player_interaction_component)


func _physics_process(_delta: float) -> void:
	if !is_activated and (plate_node.position - weighted_down_plate_position).length() <= 0.03:
		weigh_down()
	if is_activated and (plate_node.position - weighted_down_plate_position).length() > 0.03:
		weight_lifted()


func weight_lifted():
	is_activated = false
	plate_deactivated.emit()


func set_state():
	if is_activated:
		plate_node.position = weighted_down_plate_position
	else:
		plate_node.position = unweighted_plate_position


func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"is_activated" : is_activated,
		"is_usable" : is_usable,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict


func _on_plate_body_exited(body: Node) -> void:
	if body is CogitoObject:
		CogitoGlobals.debug_log(true,"cogito_pressure_plate.gd", str(body) + " has exited.")
		weight_lifted()
	if body is CogitoPlayer:
		plate_node.constant_force = Vector3(0, 0, 0)


func _on_plate_body_entered(body: Node) -> void:
	CogitoGlobals.debug_log(true,"cogito_pressure_plate.gd","Detected " + body.name)
	if body.is_in_group("Player"):
		CogitoGlobals.debug_log(true,"cogito_pressure_plate.gd", "Player detected. applying force.")
		plate_node.add_constant_central_force(Vector3(0,-3,0))
