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
	var dir = DirAccess.open(CogitoSceneManager.cogito_state_dir)
	dir.make_dir(str(state_slot))
	var scene_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_scene_state_prefix + scene_name + ".res")
	ResourceSaver.save(self, scene_state_file, ResourceSaver.FLAG_CHANGE_PATH)
	print("Scene state saved as ", scene_state_file)
	# For debug save as .tres
	#var scene_state_file_tres = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_scene_state_prefix + scene_name + ".tres")
	#ResourceSaver.save(self, scene_state_file_tres, ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_RELATIVE_PATHS)
	#print("Scene state saved as .tres: ", scene_state_file_tres)


func state_exists(state_slot : String, scene_name : String) -> bool:
	var scene_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_scene_state_prefix + scene_name + ".res")
	print("Cogito_scene_state.gd: Looking if stat exists: ", scene_state_file)
	return ResourceLoader.exists(scene_state_file)
 

func load_state(state_slot : String, scene_name : String) -> Resource:
	var scene_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_scene_state_prefix + scene_name + ".res")
	return ResourceLoader.load(scene_state_file, "", ResourceLoader.CACHE_MODE_IGNORE)
