class_name CogitoSceneState
extends Resource

var scene_state_dir : String = "res://scene_state_"

@export var saved_nodes : Array


func clear_saved_nodes():
	saved_nodes.clear()

func add_node_data_to_array(node_data):
	saved_nodes.append(node_data)


func write_state(state_slot : String, scene_name : String) -> void:
	var scene_state_file = str(scene_state_dir + state_slot + "_" + scene_name + ".res")
	ResourceSaver.save(self, scene_state_file)
	print("Scene state saved as ", scene_state_file)


func state_exists(state_slot : String, scene_name : String) -> bool:
	var scene_state_file = str(scene_state_dir + state_slot + "_" + scene_name + ".res")
	return ResourceLoader.exists(scene_state_file)
 

func load_state(state_slot : String, scene_name : String) -> Resource:
	var scene_state_file = str(scene_state_dir + state_slot + "_" + scene_name + ".res")
	return ResourceLoader.load(scene_state_file, "", 0)
