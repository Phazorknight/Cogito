extends Node

@export_file("*.tscn") var main_menu_scene
@export_file("*.tscn") var start_game_scene

func _on_main_menu_start_game_pressed():
	if start_game_scene: 
		get_tree().change_scene_to_file(start_game_scene)
	else:
		print("No start game scene set in the Scene switcher.")

func _on_pause_menu_back_to_main_pressed():
	if main_menu_scene:
		get_tree().change_scene_to_file(main_menu_scene)
	else:
		print("No main menu scene set in the Scene switcher.")
