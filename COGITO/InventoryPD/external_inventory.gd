extends StaticBody3D

@export var inventory_name : String = "Container"
@export var inventory_data : InventoryPD
@export var interaction_text : String = "Open"
var is_open : bool = false

signal toggle_inventory(external_inventory_owner)

func _ready():
	add_to_group("external_inventory")
	add_to_group("Persist")

func interact(_player):
	toggle_inventory.emit(self)


# Function to handle persistency and saving
func save():
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"inventory_name" : inventory_name,
		"inventory_data" : inventory_data,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return node_data
