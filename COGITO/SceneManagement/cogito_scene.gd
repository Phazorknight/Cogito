extends Node

# This script contains logic on scene name, state and connections to/from other scenes

@export var connectors : Array[Node3D]

func move_player_to_connector(connector_name:String):
	for node in connectors:
		if node.get_name() == connector_name:
			print("Connector found, moving player to ", node.get_name())
			CogitoSceneManager._current_player_node.global_position = node.global_position
			CogitoSceneManager._current_player_node.global_rotation = node.global_rotation
			return
	
	print("No connector with name ", connector_name, " found.")
