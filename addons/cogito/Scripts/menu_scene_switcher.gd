extends Node

## Filepath to the main menu scene.
@export_file("*.tscn") var main_menu_scene
## Filepath to the scene the player should start in, when pressing "Start game" button.
@export_file("*.tscn") var start_game_scene

func _on_main_menu_start_game_pressed():
	if start_game_scene: 
		CogitoSceneManager.load_next_scene(start_game_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
	else:
		print("menu_scene_switcher.gd: No start game scene set.")

func _on_pause_menu_back_to_main_pressed():
	if main_menu_scene:
		CogitoSceneManager.load_next_scene(main_menu_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
		CogitoSceneManager.delete_temp_saves()
	else:
		print("menu_scene_switcher.gd: No main menu scene set.")
