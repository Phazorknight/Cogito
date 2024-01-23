class_name CogitoPlayerState
extends Resource

var player_state_dir : String = "user://COGITO_player_state_"

@export var version : int = 1
@export var player_inventory : InventoryPD
@export var saved_wieldable_charges : Array

@export var player_current_scene : String
@export var player_current_scene_path : String
@export var player_position : Vector3
@export var player_rotation : Vector3

#Using Vector2 for saving player attributes. X = current, Y = max.
@export var player_health: Vector2
@export var player_stamina : Vector2
@export var player_sanity : Vector2

#Saving parameters from the player interaction component
@export var interaction_component_state : Array


func add_interaction_component_state_data_to_array(state_data):
	interaction_component_state.append(state_data)


func clear_saved_interaction_component_state():
	interaction_component_state.clear()
	
func append_saved_wieldable_charges(saved_item_data):
	saved_wieldable_charges.append(saved_item_data)
	
func clear_saved_wieldable_charges():
	saved_wieldable_charges.clear()

func write_state(state_slot : String) -> void:
	var player_state_file = str(player_state_dir + state_slot + ".res")
	ResourceSaver.save(self, player_state_file, ResourceSaver.FLAG_CHANGE_PATH)
	print("Player state saved as ", player_state_file)


func state_exists(state_slot : String) -> bool:
	var player_state_file = str(player_state_dir + state_slot + ".res")
	return ResourceLoader.exists(player_state_file)
 

func load_state(state_slot : String) -> Resource:
	var player_state_file = str(player_state_dir + state_slot + ".res")
	return ResourceLoader.load(player_state_file, "", ResourceLoader.CACHE_MODE_IGNORE)
