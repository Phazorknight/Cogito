@tool
extends Node

@export var entered_string : String = "This is a test string."
@export var is_logging: bool = false

### Save Game Settings
@export var scene_state_prefix : String = "COGITO_scene_state_"
@export var player_state_prefix : String = "COGITO_player_state_"

### Scene Settings
@export var default_transition_duration : float = .5

### Input Settings
@export var input_icons_kbm: Texture2D
@export var input_icons_xbox: Texture2D
@export var input_icons_playstation: Texture2D
@export var input_icons_steamdeck: Texture2D
@export var input_icons_switch: Texture2D

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


func _on_lineedit_player_state_text_submitted(new_text: String) -> void:
	if new_text.is_valid_filename():
		player_state_prefix = new_text
	else:
		push_error("Text must not contain invalid characters")
		player_state_prefix = "COGITO_player_state_"


func _on_lineedit_scene_state_text_submitted(new_text: String) -> void:
	if new_text.is_valid_filename():
		scene_state_prefix = new_text
	else:
		push_error("Text must not contain invalid characters")
		scene_state_prefix = "COGITO_scene_state_"


func _on_btn_git_hub_pressed() -> void:
	OS.shell_open("https://github.com/Phazorknight/Cogito")


func _on_btn_documentation_pressed() -> void:
	OS.shell_open("https://cogito.readthedocs.io/en/latest/index.html")
