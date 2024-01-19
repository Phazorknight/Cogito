extends Area3D

@export_file("*.tscn") var path_to_new_scene
@export var target_connector : String
var current_scene_statename : String
var current_scene_filepath : String

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	
func _on_body_entered(body: Node3D):
	if !body.is_in_group("Player"):
		return
	
	current_scene_statename = get_tree().get_current_scene().get_name()
	CogitoSceneManager.save_scene_state(current_scene_statename,"temp")
	CogitoSceneManager.save_player_state(CogitoSceneManager._current_player_node, "temp")
	CogitoSceneManager.load_next_scene(path_to_new_scene, target_connector, "temp", false)
	
func _on_body_exited(body: Node3D):
	if !body.is_in_group("Player"):
		return

