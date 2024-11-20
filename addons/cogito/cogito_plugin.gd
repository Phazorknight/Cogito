@tool
extends EditorPlugin
const cogito_plugin_icon : Texture2D = preload("./Cogito.svg")
const cogito_default_settings = preload("./CogitoSettings.tres")

var cog_settings : CogitoSettings


func _enter_tree():
	add_autoload_singleton("CogitoGlobals", "/cogito_globals.gd")
	add_autoload_singleton("CogitoSceneManager", "/SceneManagement/cogito_scene_manager.gd")
	add_autoload_singleton("CogitoQuestManager", "/QuestSystem/cogito_quest_manager.gd")
	add_autoload_singleton("MenuTemplateManager", "/EasyMenus/Nodes/menu_template_manager.tscn")
	
	cog_settings = cogito_default_settings
	

func _exit_tree():
	remove_autoload_singleton("CogitoQuestManager")
	remove_autoload_singleton("MenuTemplateManager")
	remove_autoload_singleton("CogitoSceneManager")
	remove_autoload_singleton("CogitoGlobals")



func _get_plugin_name():
	return "Cogito"


func _get_plugin_icon():
	return cogito_plugin_icon
