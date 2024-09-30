@tool
extends EditorPlugin
const cogito_plugin_icon : Texture2D = preload("res://addons/cogito_plugin/Cogito.svg")
const MainPanel = preload("res://addons/cogito_plugin/cogito_main_panel.tscn")
var main_panel_instance


func _enter_tree():
	add_autoload_singleton("CogitoMain", "./cogito_main.gd")
	add_autoload_singleton("CogitoSceneManager", "./SceneManagement/cogito_scene_manager.gd")
	add_autoload_singleton("CogitoQuestManager", "./QuestSystem/cogito_quest_manager.gd")
	main_panel_instance = MainPanel.instantiate()
	# Add the main panel to the editor's main viewport.
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	# Hide the main panel. Very much required.
	_make_visible(false)


func _exit_tree():
	remove_autoload_singleton("CogitoQuestManager")
	remove_autoload_singleton("CogitoSceneManager")
	remove_autoload_singleton("CogitoMain")
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name():
	return "Cogito"


func _get_plugin_icon():
	return cogito_plugin_icon
