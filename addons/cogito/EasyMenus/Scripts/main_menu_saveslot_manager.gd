extends Control

@onready var save_slot_a: CogitoSaveSlotButton = %SaveSlot_A
@onready var save_slot_b: CogitoSaveSlotButton = %SaveSlot_B
@onready var save_slot_c: CogitoSaveSlotButton = %SaveSlot_C

## Filepath to the scene the player should start in, when pressing "Start game" button.
#@export_file("*.tscn") var start_game_scene

@export var new_game_start_scene : PackedScene


@export var new_game_world_dict : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_all_save_slots()


func load_all_save_slots():
	save_slot_a.set_data_from_state(load_slot_data(save_slot_a.manual_save_slot_name))
	save_slot_b.set_data_from_state(load_slot_data(save_slot_b.manual_save_slot_name))
	save_slot_c.set_data_from_state(load_slot_data(save_slot_c.manual_save_slot_name))


func load_slot_data(save_slot: String) -> CogitoPlayerState:
	# Set CSM active slot to slot to load
	CogitoSceneManager.switch_active_slot_to(save_slot)
	if CogitoSceneManager._player_state == null:
		return null
	else:
		return CogitoSceneManager._player_state
	

func start_new_game():
	if new_game_start_scene:
		var path_to_scene = new_game_start_scene.resource_path
		CogitoSceneManager.load_next_scene(path_to_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
		
		#Setting new game world state:
		CogitoSceneManager._current_world_dict = new_game_world_dict
		
	#if start_game_scene: 
		#CogitoSceneManager.load_next_scene(start_game_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
	else:
		print("ISSUE: No start game scene set.")
