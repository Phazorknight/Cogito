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


func _on_btn_reset_input_map_pressed() -> void:
	
	var keyboard_key = InputEventKey.new()
	var mouse_button = InputEventMouseButton.new()
	var gamepad_button = InputEventJoypadButton.new()
	var gamepad_motion = InputEventJoypadMotion.new()
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_W
	gamepad_motion = InputEventJoypadMotion.new()
	gamepad_motion.device = -1
	gamepad_motion.axis = JOY_AXIS_LEFT_Y
	gamepad_motion.axis_value = -1.0
	save_input_action_to_settings("forward",keyboard_key,gamepad_motion)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_S
	gamepad_motion = InputEventJoypadMotion.new()
	gamepad_motion.device = -1
	gamepad_motion.axis = JOY_AXIS_LEFT_Y
	gamepad_motion.axis_value = 1.0
	save_input_action_to_settings("back",keyboard_key,gamepad_motion)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_A
	gamepad_motion = InputEventJoypadMotion.new()
	gamepad_motion.device = -1
	gamepad_motion.axis = JOY_AXIS_LEFT_X
	gamepad_motion.axis_value = -1.0
	save_input_action_to_settings("left",keyboard_key,gamepad_motion)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_D
	gamepad_motion = InputEventJoypadMotion.new()
	gamepad_motion.device = -1
	gamepad_motion.axis = JOY_AXIS_LEFT_X
	gamepad_motion.axis_value = 1.0
	save_input_action_to_settings("right",keyboard_key,gamepad_motion)
	
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
	
	mouse_button.button_index = MOUSE_BUTTON_LEFT
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_X
	save_input_action_to_settings("inventory_move_item",mouse_button,gamepad_button)
	
	mouse_button.button_index = MOUSE_BUTTON_RIGHT
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_A
	save_input_action_to_settings("inventory_use_item",mouse_button,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_G
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_Y
	save_input_action_to_settings("inventory_drop_item",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_R
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_X
	save_input_action_to_settings("reload",keyboard_key,gamepad_button)
	
	# I've not found a way to update the project settings input map editor but to restart the whole editor.
	# WARNING: NEEDS TO BE COMMENTED OUT FOR EXPORT as it will otherwise break your build.
	# EditorInterface.restart_editor(true)


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
