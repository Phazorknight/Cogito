extends Node

## List of connector nodes. These are used to place the Player in the correct position when they transition to this scene from a different scene. The Node name needs to match the passed string for this to work.
@export var connectors : Array[Node3D]

func move_player_to_connector(connector_name:String):
	for node in connectors:
		if node.get_name() == connector_name:
			print("Connector found, moving player to ", node.get_name())
			CogitoSceneManager._current_player_node.global_position = node.global_position
			CogitoSceneManager._current_player_node.global_rotation = node.global_rotation
			return
	
	print("No connector with name ", connector_name, " found.")

func _enter_tree() -> void:
	CogitoSceneManager._current_scene_root_node = self
	print("Cogito Scene: Current scene root node set to ", CogitoSceneManager._current_scene_root_node.name)
