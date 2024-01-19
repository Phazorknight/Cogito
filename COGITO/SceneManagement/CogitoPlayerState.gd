class_name CogitoPlayerState
extends Resource

var player_state_dir : String = "res://player_state_"

@export var version : int = 1
@export var player_inventory : InventoryPD

@export var player_current_scene : String
@export var player_current_scene_path : String
@export var player_position : Vector3
@export var player_rotation : Vector3

#Using Vector2 for saving player attributes. X = current, Y = max.
@export var player_health: Vector2
@export var player_stamina : Vector2
@export var player_sanity : Vector2

var _file : FileAccess

func write_state(state_slot : String) -> void:
	var player_state_file = str(player_state_dir + state_slot + ".res")
	ResourceSaver.save(self, player_state_file)
	print("Player state saved as ", player_state_file)


func state_exists(state_slot : String) -> bool:
	var player_state_file = str(player_state_dir + state_slot + ".res")
	return ResourceLoader.exists(player_state_file)
 

func load_state(state_slot : String) -> Resource:
	var player_state_file = str(player_state_dir + state_slot + ".res")
	return ResourceLoader.load(player_state_file, "", 0)
