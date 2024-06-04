extends Area3D

## Filepath to scene this zone transitions to.
@export_file("*.tscn") var path_to_new_scene
## Name of connector node the player should transition to in target scene. This node needs to exist in the target scene and has to be added to the connector array of the target scene cogito_scene script.
@export var target_connector : String

var current_scene_statename : String
var current_scene_filepath : String

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	
func _on_body_entered(body: Node3D):
	if !body.is_in_group("Player"):
		return
	
	transition_to_next_scene()

	
func _on_body_exited(body: Node3D):
	if !body.is_in_group("Player"):
		return


func transition_to_next_scene():
	current_scene_statename = get_tree().get_current_scene().get_name()
	CogitoSceneManager.save_scene_state(current_scene_statename,"temp")
	CogitoSceneManager.save_player_state(CogitoSceneManager._current_player_node, "temp")
	CogitoSceneManager.load_next_scene(path_to_new_scene, target_connector, "temp", CogitoSceneManager.CogitoSceneLoadMode.TEMP)
