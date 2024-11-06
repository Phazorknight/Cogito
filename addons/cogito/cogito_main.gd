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


func _on_btn_reset_input_map_pressed() -> void:
	
	var keyboard_key = InputEventKey.new()
	var mouse_button = InputEventMouseButton.new()
	var gamepad_button = InputEventJoypadButton.new()
	var gamepad_motion = InputEventJoypadMotion.new()
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_SPACE
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_A
	save_input_action_to_settings("jump",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_C
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_B
	save_input_action_to_settings("crouch",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_SHIFT
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_LEFT_STICK
	save_input_action_to_settings("sprint",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_ESCAPE
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_START
	save_input_action_to_settings("menu",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_F
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_X
	save_input_action_to_settings("interact",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_E
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_Y
	save_input_action_to_settings("interact2",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_TAB
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_BACK
	save_input_action_to_settings("inventory",keyboard_key,gamepad_button)
	
	mouse_button.button_index = MOUSE_BUTTON_LEFT
	gamepad_motion = InputEventJoypadMotion.new()
	gamepad_motion.device = -1
	gamepad_motion.axis = JOY_AXIS_TRIGGER_RIGHT
	save_input_action_to_settings("action_primary",mouse_button,gamepad_motion)
	
	mouse_button.button_index = MOUSE_BUTTON_RIGHT
	gamepad_motion = InputEventJoypadMotion.new()
	gamepad_motion.device = -1
	gamepad_motion.axis = JOY_AXIS_TRIGGER_LEFT
	save_input_action_to_settings("action_secondary",mouse_button,gamepad_motion)
	
	# I've not found a way to update the project settings input map editor but to restart the whole editor.
	EditorInterface.restart_editor(true)


func save_input_action_to_settings(input_name: String, input_kbm:InputEventWithModifiers, input_gamepad:InputEvent):
	var input = {
		"deadzone": 0.5,
		"events": [
			input_kbm,
			input_gamepad
		]
	}
	
	var setting_name = 'input/' + input_name
	# Set the input/<name_of_your_input_action> in the project settings, then save the settings.
	ProjectSettings.set_setting(setting_name, input)
	ProjectSettings.save()
	print("COGITO: Saved input to settings: ", setting_name, ". input_kbm=", input_kbm, ". input_gamepad=", input_gamepad)
