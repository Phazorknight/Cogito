@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends Node3D
class_name CogitoStaticInteractable

signal damage_received(damage_value:float)

var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null

func _ready():
	self.add_to_group("interactable")
	find_interaction_nodes()

func find_interaction_nodes():
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components

#
## Function to handle persistence and saving
#func save():
	#var node_data = {
		#"filename" : get_scene_file_path(),
		#"parent" : get_parent().get_path(),
		##"slot_data" : slot_data,
		##"item_charge" : slot_data.inventory_item.charge_current,
		#"interaction_nodes" : interaction_nodes,
		#"pos_x" : position.x,
		#"pos_y" : position.y,
		#"pos_z" : position.z,
		#"rot_x" : rotation.x,
		#"rot_y" : rotation.y,
		#"rot_z" : rotation.z,
		#
	#}
	#return node_data
