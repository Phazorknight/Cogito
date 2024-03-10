class_name CogitoSceneState
extends Resource

var scene_state_dir : String = CogitoSceneManager.cogito_state_dir + CogitoSceneManager.cogito_scene_state_prefix

@export var saved_nodes : Array
@export var saved_states : Array


func clear_saved_nodes():
	saved_nodes.clear()
	
func clear_saved_states():
	saved_states.clear()

func add_node_data_to_array(node_data):
	saved_nodes.append(node_data)

func add_state_data_to_array(state_data):
	saved_states.append(state_data)

func write_state(state_slot : String, scene_name : String) -> void:
	var scene_state_file = str(scene_state_dir + state_slot + "_" + scene_name + ".res")
	ResourceSaver.save(self, scene_state_file, ResourceSaver.FLAG_CHANGE_PATH)
	print("Scene state saved as ", scene_state_file)


func state_exists(state_slot : String, scene_name : String) -> bool:
	var scene_state_file = str(scene_state_dir + state_slot + "_" + scene_name + ".res")
	return ResourceLoader.exists(scene_state_file)
 

func load_state(state_slot : String, scene_name : String) -> Resource:
	var scene_state_file = str(scene_state_dir + state_slot + "_" + scene_name + ".res")
	return ResourceLoader.load(scene_state_file, "", ResourceLoader.CACHE_MODE_IGNORE)
