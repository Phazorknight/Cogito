@tool
extends Node

var cogito_settings : CogitoSettings
var cogito_settings_filepath := "res://addons/cogito/CogitoSettings.tres"

### Cached settings
var is_logging : bool
var player_state_prefix : String
var scene_state_prefix : String
var default_transition_duration : float = .4


func _ready() -> void:
	load_cogito_project_settings()


func _enter_tree() -> void:
	load_cogito_project_settings()


func load_cogito_project_settings():
	if ResourceLoader.exists(cogito_settings_filepath):
		cogito_settings = ResourceLoader.load(cogito_settings_filepath, "", ResourceLoader.CACHE_MODE_IGNORE)
		print("COGITO: cogito settings loaded: ", cogito_settings_filepath)
		
		is_logging = cogito_settings.is_logging
		player_state_prefix = cogito_settings.player_state_prefix
		scene_state_prefix = cogito_settings.scene_state_prefix
		default_transition_duration = cogito_settings.default_transition_duration
		
	else:
		print("COGITO: No cogito settings found.")


func debug_log(log_this: bool, _class: String, _message: String) -> void:
	if is_logging and log_this:
		print("COGITO: ", _class, ": ", _message)


func _on_check_box_print_logs_toggled(toggled_on: bool) -> void:
	is_logging = toggled_on


func _on_lineedit_fade_duration_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		default_transition_duration = float(new_text)
	else:
		push_error("Must enter valid float value.")
		default_transition_duration = .5


func _on_btn_git_hub_pressed() -> void:
	OS.shell_open("https://github.com/Phazorknight/Cogito")


func _on_btn_documentation_pressed() -> void:
	OS.shell_open("https://cogito.readthedocs.io/en/latest/index.html")


func _on_btn_video_tutorials_pressed() -> void:
	OS.shell_open("https://cogito.readthedocs.io/en/latest/tutorials.html")
