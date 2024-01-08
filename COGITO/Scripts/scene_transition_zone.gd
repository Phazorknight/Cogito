extends Area3D

@export_file("*.tscn") var path_to_new_scene
@export var ignore_target_scene_state : bool = false
var current_scene_savename : String

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	
func _on_body_entered(body: Node3D):
	if !body.is_in_group("Player"):
		return
	
	current_scene_savename = get_tree().get_current_scene().get_name()
	CogitoSceneManager.save_scene_state(current_scene_savename)
	CogitoSceneManager.load_next_scene(path_to_new_scene, ignore_target_scene_state)
	
func _on_body_exited(body: Node3D):
	if !body.is_in_group("Player"):
		return

