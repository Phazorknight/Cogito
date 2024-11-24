@tool
class_name CogitoSettings extends Resource

const settings_path := "res://addons/cogito/"
const settings_filename := "CogitoSettings"

@export var is_logging: bool = false

@export var scene_state_prefix : String = "COGITO_scene_state_"
@export var player_state_prefix : String = "COGITO_player_state_"

@export var default_transition_duration : float = .5


#func save_settings(file_path: String) -> void:
	#var full_settings_filepath = settings_path + settings_filename + ".tres"
	#ResourceSaver.save(self, file_path, ResourceSaver.FLAG_CHANGE_PATH)
	#print("CogitoSettingsFile: Cogito Settings saved as ", file_path)

#
#func settings_exist() -> bool:
	##var player_state_file = str(player_state_dir + state_slot + ".res")
	#var full_settings_filepath = settings_path + settings_filename + ".tres"
	#return ResourceLoader.exists(full_settings_filepath)
 #
#
#func load_settings(state_slot : String) -> Resource:
	#var full_settings_filepath = settings_path + settings_filename + ".tres"
	#return ResourceLoader.load(full_settings_filepath, "CogitoSettings", ResourceLoader.CACHE_MODE_IGNORE)
