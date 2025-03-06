@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoContainer.svg")
extends Node3D
class_name CogitoContainer

@export_group("Container Settings")
## Name that will displayed when interacting. Leave blank to hide
@export var display_name : String = "Container"
@export var inventory_data : CogitoInventory
@export var text_when_closed : String = "Open"
@export var text_when_open : String = "Close"

@export_group("Animation Settings")
@export var uses_animation : bool = false
@export var open_animation : String
@export var use_reverse_open_as_close_anim : bool
@export var close_animation : String

@onready var animation_player : AnimationPlayer = $AnimationPlayer

var interaction_text
var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null

signal toggle_inventory(external_inventory_owner)
signal object_state_updated(interaction_text:String)
signal container_closed


func _ready():
	add_to_group("external_inventory")
	add_to_group("interactable")
	add_to_group("save_object_state")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	interaction_text = text_when_closed
	object_state_updated.emit(interaction_text)
	inventory_data.apply_initial_inventory()

func interact(_player_interaction_component: PlayerInteractionComponent):
	toggle_inventory.emit(self)


func open():
	if uses_animation:
		animation_player.play(open_animation)
	interaction_text = text_when_open
	object_state_updated.emit(interaction_text)


func close():
	if uses_animation:
		if use_reverse_open_as_close_anim:
			animation_player.play_backwards(open_animation)
		else:
			animation_player.play(close_animation)
	interaction_text = text_when_closed
	object_state_updated.emit(interaction_text)
	container_closed.emit()


func set_state():
	interaction_text = text_when_closed
	animation_player = $AnimationPlayer
	object_state_updated.emit(interaction_text)


# Function to handle persistency and saving
func save():
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"node_path" : self.get_path(),
		"display_name" : display_name,
		"inventory_data" : inventory_data,
		"interaction_nodes" : interaction_nodes,
		"animation_player" : animation_player,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return node_data
