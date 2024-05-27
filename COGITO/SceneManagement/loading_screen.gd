extends CanvasLayer
# Loading screen script is heavily dependent on Cogito Scene Manager and scene states.
# MODIFY AT YOUR OWN RISK. Besides the forced_delay, there aren't really any tweakable parameters here.


## Adds a forced wait time to the loading screen. Used to avoid loading screen flickering if load time is too short.
@export var forced_delay : float = 0.5

var next_scene_path : String
var connector_name : String
var next_scene_state_filename : String
var passed_slot : String
var load_mode

func _ready():
	ResourceLoader.load_threaded_request(next_scene_path) # Start loading the next scene


func _process(_delta):
	if ResourceLoader.load_threaded_get_status(next_scene_path) == ResourceLoader.THREAD_LOAD_LOADED:
		print("Loading screen: Attempting to load ", next_scene_path)
		set_process(false)
		await get_tree().create_timer(forced_delay).timeout
		var new_scene_packed: PackedScene = ResourceLoader.load_threaded_get(next_scene_path)
		var new_scene_node = new_scene_packed.instantiate()
		var current_scene = get_tree().current_scene # Stores currently active scene so it can be set later
		get_tree().get_root().add_child(new_scene_node) # Adds the instatiated new scene as a node.
		
		print("Loading screen: Load_mode is ", load_mode)
		
		#If load_mode asks for it, scene state will be loaded.
		if load_mode != 2: #Checking that load_mode is not set to 2 which would ignore scene states.
			
			next_scene_state_filename = new_scene_node.get_name()
			
			# This flag is used if the scene transition was called from loading a save
			if load_mode == 1: #Load_Mode one is attempting to load a save
				print("Loading screen: Attempting to load a save for passsed_slot ", passed_slot)
				CogitoSceneManager._current_scene_name = new_scene_node.name #Manually setting new scene name
				CogitoSceneManager.loading_saved_game(passed_slot)
			else:
				print("Loading screen: Attempting to load scene state: ", next_scene_state_filename)
				CogitoSceneManager.load_scene_state(next_scene_state_filename,"temp") # Loading temp scene state
				CogitoSceneManager.load_player_state(CogitoSceneManager._current_player_node,"temp") # Loading temp player state.
		
		get_tree().current_scene = new_scene_node # Assigns new scene as current scene
		
		if connector_name != "": #If a connector name has been passed, move the player to it. This requires the target scene to have a cogito scene script attached to it's root scene node.
			new_scene_node.move_player_to_connector(connector_name)
		current_scene.queue_free() # Removing previous scene.
