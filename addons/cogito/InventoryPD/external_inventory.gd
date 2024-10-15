extends StaticBody3D

@export var inventory_name : String = "Container"
@export var inventory_data : CogitoInventory
@export var text_when_closed : String = "Open"
@export var text_when_open : String = "Close"
var interaction_text
var is_open : bool = false
var interaction_nodes : Array[Node]

@onready var animation_player: AnimationPlayer
@export var uses_animation : bool
@export var open_animation : String

signal toggle_inventory(external_inventory_owner)
signal object_state_updated(interaction_text:String)

func _ready():
	add_to_group("external_inventory")
	add_to_group("Persist")
	add_to_group("interactable")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	interaction_text = text_when_closed
	animation_player = $AnimationPlayer
	inventory_data.apply_initial_inventory()

func interact(_player):
	toggle_inventory.emit(self)

func open():
	if uses_animation:
		animation_player.play(open_animation)
	interaction_text = text_when_open
	object_state_updated.emit(interaction_text)

func close():
	if uses_animation:
		animation_player.play_backwards(open_animation)
	interaction_text = text_when_closed
	object_state_updated.emit(interaction_text)


# Function to handle persistency and saving
func save():
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"inventory_name" : inventory_name,
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
