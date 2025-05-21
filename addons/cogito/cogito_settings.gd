@tool
class_name CogitoSettings extends Resource

const settings_path := "res://addons/cogito/"
const settings_filename := "CogitoSettings"

## When this is checked, most Cogito scripts and objects will print messages in the output. Turn this on if you want to track and understand certain behaviors or have issues.
@export var is_logging: bool = false

## The prefix used in scene state save files, followed by the save slot name. Be aware that changing this will impact if/how Cogito detects existing save files.
@export var scene_state_prefix : String = "COGITO_scene_state_"
## The prefix used in player state save files, followed by the save slot name. Be aware that changing this will impact if/how Cogito detects existing save files.
@export var player_state_prefix : String = "COGITO_player_state_"

@export var auto_save_name : String = "autosave"

## The default fade duration on scene changes.
@export var default_transition_duration : float = .5

## Debug functions of loot component are toggled here.
@export_group("Loot Component Debug")
## This variable toggles the LootComponent.gd's debug functions.
@export var loot_component_debug: bool = false
## This variable toggles the cogito_loot_generator.gd's debug functions.
@export var loot_generator_debug: bool = false
## This variable toggles the cogito_loot_drop_container.gd's debug functions.
@export var loot_drop_container_debug: bool = false
## This variable toggles the cogito_lootable_container.gd's debug functions.
@export var lootable_container_debug: bool = false

@export_group("Danger Zone")
## WARNING: If you press this, your projects input map settings will be reset/overwritten! You need to manually restart your project for this to take effect.
@export_tool_button("Reset Project Input Map") var reset_input_map_action = _on_btn_reset_input_map_pressed


#func save_settings(file_path: String) -> void:
	#var full_settings_filepath = settings_path + settings_filename + ".tres"
	#ResourceSaver.save(self, file_path, ResourceSaver.FLAG_CHANGE_PATH)
	#print("CogitoSettingsFile: Cogito Settings saved as ", file_path)


#func settings_exist() -> bool:
	##var player_state_file = str(player_state_dir + state_slot + ".res")
	#var full_settings_filepath = settings_path + settings_filename + ".tres"
	#return ResourceLoader.exists(full_settings_filepath)


#func load_settings(state_slot : String) -> Resource:
	#var full_settings_filepath = settings_path + settings_filename + ".tres"
	#return ResourceLoader.load(full_settings_filepath, "CogitoSettings", ResourceLoader.CACHE_MODE_IGNORE)


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
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_1
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_DPAD_LEFT
	save_input_action_to_settings("quickslot_1",keyboard_key,gamepad_button)

	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_2
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_DPAD_UP
	save_input_action_to_settings("quickslot_2",keyboard_key,gamepad_button)

	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_3
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_DPAD_RIGHT
	save_input_action_to_settings("quickslot_3",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_4
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_DPAD_DOWN
	save_input_action_to_settings("quickslot_4",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_CAPSLOCK
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_RIGHT_SHOULDER
	save_input_action_to_settings("free_look",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_E
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_RIGHT_SHOULDER
	save_input_action_to_settings("ui_next_tab",keyboard_key,gamepad_button)
	
	keyboard_key = InputEventKey.new()
	keyboard_key.physical_keycode = KEY_Q
	gamepad_button = InputEventJoypadButton.new()
	gamepad_button.device = -1
	gamepad_button.button_index = JOY_BUTTON_LEFT_SHOULDER
	save_input_action_to_settings("ui_prev_tab",keyboard_key,gamepad_button)


	
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
