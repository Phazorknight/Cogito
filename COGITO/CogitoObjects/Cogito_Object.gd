@icon("res://COGITO/Assets/Graphics/Editor/CogitoNodeIcon.svg")
extends Node3D
class_name CogitoObject

signal damage_received(damage_value:float)

var interaction_nodes : Array[Node]

func _ready():
	self.add_to_group("interactable")
	self.add_to_group("Persist") #Adding object to group for persistence
	find_interaction_nodes()


# Future method to set object state when a scene state file is loaded.
func set_state():	
	#TODO: Find a way to possibly save health of health attribute.
	pass


func find_interaction_nodes():
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components


# Function to handle persistence and saving
func save():
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		#"slot_data" : slot_data,
		#"item_charge" : slot_data.inventory_item.charge_current,
		"interaction_nodes" : interaction_nodes,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return node_data
