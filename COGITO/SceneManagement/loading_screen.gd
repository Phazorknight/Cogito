extends CanvasLayer

## Adds a forced wait time to the loading screen. Used to avoid loading screen flickering if load time is too short.
@export var forced_delay : float = 0.5

var next_scene_path : String
var next_scene_state_filename : String
var ignore_scene_state : bool = false

func _ready():
	ResourceLoader.load_threaded_request(next_scene_path) # Start loading the next scene


func _process(_delta):
	if ResourceLoader.load_threaded_get_status(next_scene_path) == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		await get_tree().create_timer(forced_delay).timeout
		var new_scene: PackedScene = ResourceLoader.load_threaded_get(next_scene_path)
		var new_node = new_scene.instantiate()
		var current_scene = get_tree().current_scene # Stores currently active scene so it can be set later
		get_tree().get_root().add_child(new_node) # Adds the instatiated new scene as a node.
		
		# At this point the new scene state can be loaded
		next_scene_state_filename = new_node.get_name()
		if !ignore_scene_state:
			CogitoSceneManager.load_scene_state(next_scene_state_filename)
		
		get_tree().current_scene = new_node # Assigns new scene as current scene
		current_scene.queue_free() # Removing previous scene.
	
