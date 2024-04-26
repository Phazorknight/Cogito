extends Node

## List of connector nodes. These are used to place the Player in the correct position when they transition to this scene from a different scene. The Node name needs to match the passed string for this to work.
@export var connectors : Array[Node3D]


func _ready() -> void:
	var player_hud = UserInterface.player_hud_scene.instantiate()
	var pause_menu = UserInterface.pause_menu_scene.instantiate()
	add_child(player_hud)
	add_child(pause_menu)
	CogitoSceneManager._current_player_node.player_hud = player_hud.get_path()
	CogitoSceneManager._current_player_node.pause_menu = pause_menu.get_path()
	pause_menu.resume.connect(CogitoSceneManager._current_player_node._on_pause_menu_resume) # Hookup resume signal from Pause Menu
	pause_menu.close_pause_menu() # Making sure pause menu is closed on player scene load


func move_player_to_connector(connector_name:String):
	for node in connectors:
		if node.get_name() == connector_name:
			print("Connector found, moving player to ", node.get_name())
			CogitoSceneManager._current_player_node.global_position = node.global_position
			CogitoSceneManager._current_player_node.global_rotation = node.global_rotation
			return
	
	print("No connector with name ", connector_name, " found.")
