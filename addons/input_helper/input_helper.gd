extends Node


signal device_changed(device: String, device_index: int)
signal keyboard_input_changed(action: String, input: InputEvent)
signal joypad_input_changed(action: String, input: InputEvent)
signal joypad_changed(device_index: int, is_connected: bool)


const DEVICE_KEYBOARD = "keyboard"
const DEVICE_XBOX_CONTROLLER = "xbox"
const DEVICE_SWITCH_CONTROLLER = "switch"
const DEVICE_PLAYSTATION_CONTROLLER = "playstation"
const DEVICE_STEAMDECK_CONTROLLER = "steamdeck"
const DEVICE_GENERIC = "generic"

const SUB_DEVICE_XBOX_ONE_CONTROLLER = "xbox_one"
const SUB_DEVICE_XBOX_SERIES_CONTROLLER = "xbox_series"
const SUB_DEVICE_PLAYSTATION3_CONTROLLER = "playstation3"
const SUB_DEVICE_PLAYSTATION4_CONTROLLER = "playstation4"
const SUB_DEVICE_PLAYSTATION5_CONTROLLER = "playstation5"
const SUB_DEVICE_SWITCH_JOYCON_LEFT_CONTROLLER = "switch_left_joycon"
const SUB_DEVICE_SWITCH_JOYCON_RIGHT_CONTROLLER = "switch_right_joycon"

const XBOX_BUTTON_LABELS = ["A", "B", "X", "Y", "Back", "Guide", "Start", "Left Stick", "Right Stick", "LB", "RB", "Up", "Down", "Left", "Right"]
const XBOX_ONE_BUTTON_LABELS = ["A", "B", "X", "Y", "View", "Guide", "Menu", "Left Stick", "Right Stick", "LB", "RB", "Up", "Down", "Left", "Right"]
const XBOX_SERIES_BUTTON_LABELS = ["A", "B", "X", "Y", "View", "Guide", "Menu", "Left Stick", "Right Stick", "LB", "RB", "Up", "Down", "Left", "Right", "Share"]
# Note: share and home buttons are not recognized
const SWITCH_BUTTON_LABELS = ["A", "B", "X", "Y", "Minus", "", "Plus", "Left Stick", "Right Stick", "SL", "SR", "Up", "Down", "Left", "Right"]
# Mapping for left and right joypad connected together (extended gamepad)
# Left Stick is Axis 0 and 1
# Right Stick is Axis 2 and 3
# ZL and ZR are Axis 4 and 5
const SWITCH_EXTENDED_GAMEPAD_BUTTON_LABELS = ["A", "B", "X", "Y", "Minus", "", "Plus", "Left Stick", "Right Stick", "L", "R", "Up", "Down", "Left", "Right"]
const PLAYSTATION_3_4_BUTTON_LABELS = ["Cross", "Circle", "Square", "Triangle", "Share", "PS", "Options", "L3", "R3", "L1", "R1", "Up", "Down", "Left", "Right"]
# Note: Microphone does not work on PC / touchpad is not recognized
const PLAYSTATION_5_BUTTON_LABELS = ["Cross", "Circle", "Square", "Triangle", "Create", "PS", "Options", "L3", "R3", "L1", "R1", "Up", "Down", "Left", "Right", "Microphone"]
const STEAMDECK_BUTTON_LABELS = ["A", "B", "X", "Y", "View", "?", "Options", "Left Stick", "Right Stick", "L1", "R1", "Up", "Down", "Left", "Right"]

const SERIAL_VERSION = 1

## The deadzone to ignore for joypad motion
var deadzone: float = 0.5
## The mouse distance to ignore before movement is assumed
var mouse_motion_threshold: int = 100
## The last known joypad device name (or "" if no joypad detected)
var last_known_joypad_device: String = get_simplified_device_name(Input.get_joy_name(0))
## The last known joypad index
var last_known_joypad_index: int = 0 if Input.get_connected_joypads().size() > 0 else -1

## Used internally
var device_last_changed_at: int = 0

@onready var device: String = guess_device_name()
@onready var device_index: int = 0 if has_joypad() else -1


func _ready() -> void:
	if not Engine.has_singleton("InputHelper"):
		Engine.register_singleton("InputHelper", self)

	Input.joy_connection_changed.connect(func(device_index, is_connected): joypad_changed.emit(device_index, is_connected))


func _input(event: InputEvent) -> void:
	var next_device: String = device
	var next_device_index: int = device_index

	# Did we just press a key on the keyboard or move the mouse?
	if event is InputEventKey \
		or event is InputEventMouseButton \
		or (event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length_squared() > mouse_motion_threshold):
		next_device = DEVICE_KEYBOARD
		next_device_index = -1

	# Did we just use a joypad?
	elif event is InputEventJoypadButton \
		or (event is InputEventJoypadMotion and abs(event.axis_value) > deadzone):
		next_device = get_simplified_device_name(Input.get_joy_name(event.device))
		last_known_joypad_device = next_device
		next_device_index = event.device
		last_known_joypad_index = next_device_index

	# Debounce changes for 1 second because some joypads register twice in Windows for some reason
	var not_changed_in_last_second = Engine.get_frames_drawn() - device_last_changed_at > Engine.get_frames_per_second()
	if (next_device != device or next_device_index != device_index) and not_changed_in_last_second:
		device_last_changed_at = Engine.get_frames_drawn()

		device = next_device
		device_index = next_device_index
		device_changed.emit(device, device_index)


## Get the device name for an event
func get_device_from_event(event: InputEvent) -> String:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		return DEVICE_KEYBOARD
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return get_simplified_device_name(Input.get_joy_name(event.device))
	else:
		return DEVICE_GENERIC


## Get the device name for an event
func get_device_index_from_event(event: InputEvent) -> int:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	else:
		return -1


## Convert a Godot device identifier to a simplified string
func get_simplified_device_name(raw_name: String) -> String:
	var keywords: Dictionary = {
		SUB_DEVICE_XBOX_ONE_CONTROLLER: ["Xbox One Controller"],
		SUB_DEVICE_XBOX_SERIES_CONTROLLER: ["Xbox Series Controller", "Xbox Wireless Controller"],
		DEVICE_XBOX_CONTROLLER: ["XInput", "XBox"],
		SUB_DEVICE_PLAYSTATION3_CONTROLLER: ["PS3"],
		SUB_DEVICE_PLAYSTATION4_CONTROLLER:["Nacon Revolution Unlimited Pro Controller", "PS4", "DUALSHOCK 4"],
		SUB_DEVICE_PLAYSTATION5_CONTROLLER:["Sony DualSense", "PS5", "DualSense Wireless Controller"],
		DEVICE_STEAMDECK_CONTROLLER: ["Steam"],
		DEVICE_SWITCH_CONTROLLER: ["Switch", "Joy-Con (L/R)", "PowerA Core Controller"],
		SUB_DEVICE_SWITCH_JOYCON_LEFT_CONTROLLER: ["Joy-Con (L)"],
		SUB_DEVICE_SWITCH_JOYCON_RIGHT_CONTROLLER: ["joy-Con (R)"],
	} if InputHelperSettings.get_setting(InputHelperSettings.USE_GRANULAR_DEVICE_IDENTIFIERS, false) else {
		DEVICE_XBOX_CONTROLLER: ["XBox", "XInput"],
		DEVICE_PLAYSTATION_CONTROLLER: ["Sony", "PS3", "PS5", "PS4", "DUALSHOCK 4", "DualSense", "Nacon Revolution Unlimited Pro Controller"],
		DEVICE_STEAMDECK_CONTROLLER: ["Steam"],
		DEVICE_SWITCH_CONTROLLER: ["Switch", "Joy-Con", "PowerA Core Controller"],
	}

	for device_key in keywords:
		for keyword in keywords[device_key]:
			if keyword.to_lower() in raw_name.to_lower():
				return device_key

	return DEVICE_GENERIC


## Check if there is a connected joypad
func has_joypad() -> bool:
	return Input.get_connected_joypads().size() > 0


## Guess the initial input device
func guess_device_name() -> String:
	if has_joypad():
		return get_simplified_device_name(Input.get_joy_name(0))
	else:
		return DEVICE_KEYBOARD


#region Mapping


func reset_all_actions() -> void:
	InputMap.load_from_project_settings()
	for action in InputMap.get_actions():
		var input: InputEvent = get_joypad_input_for_action(action)
		if input != null:
			joypad_input_changed.emit(action, input)

		input = get_keyboard_input_for_action(action)
		if input != null:
			keyboard_input_changed.emit(action, input)


## Set the key or button for an action
func set_keyboard_or_joypad_input_for_action(action: String, event: InputEvent, swap_if_taken: bool = true) -> void:
	if event is InputEventKey or event is InputEventMouse:
		set_keyboard_input_for_action(action, event, swap_if_taken)
	elif event is InputEventJoypadButton:
		set_joypad_input_for_action(action, event, swap_if_taken)


## Get the key or button for a given action depending on the current device
func get_keyboard_or_joypad_input_for_action(action: String) -> InputEvent:
	if device == DEVICE_KEYBOARD:
		return get_keyboard_input_for_action(action)
	else:
		return get_joypad_input_for_action(action)


## Get the key or button for a given action depending on the current device
func get_keyboard_or_joypad_inputs_for_action(action: String) -> Array[InputEvent]:
	if device == DEVICE_KEYBOARD:
		return get_keyboard_inputs_for_action(action)
	else:
		return get_joypad_inputs_for_action(action)


## Get a text label for a given input
func get_label_for_input(input: InputEvent) -> String:
	if input == null: return ""

	if input is InputEventKey:
		if input.physical_keycode > 0 :
			var keycode: Key = DisplayServer.keyboard_get_keycode_from_physical(input.physical_keycode) if DisplayServer.keyboard_get_current_layout() > -1 else input.physical_keycode
			return OS.get_keycode_string(keycode)
		elif input.keycode > 0:
			return OS.get_keycode_string(input.keycode)
		else:
			return input.as_text()

	elif input is InputEventMouseButton:
		match input.button_index:
			MOUSE_BUTTON_LEFT:
				return "Mouse Left Button"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse Middle Button"
			MOUSE_BUTTON_RIGHT:
				return "Mouse Right Button"
		return "Mouse Button %d" % input.button_index

	elif input is InputEventJoypadButton:
		match last_known_joypad_device:
			DEVICE_XBOX_CONTROLLER, DEVICE_GENERIC:
				return "%s Button" % XBOX_BUTTON_LABELS[input.button_index]
			SUB_DEVICE_XBOX_ONE_CONTROLLER:
				return "%s Button" % XBOX_ONE_BUTTON_LABELS[input.button_index]
			SUB_DEVICE_XBOX_SERIES_CONTROLLER:
				return "%s Button" % XBOX_SERIES_BUTTON_LABELS[input.button_index]
			SUB_DEVICE_SWITCH_JOYCON_LEFT_CONTROLLER, SUB_DEVICE_SWITCH_JOYCON_RIGHT_CONTROLLER:
				return "%s Button" % SWITCH_BUTTON_LABELS[input.button_index]
			DEVICE_SWITCH_CONTROLLER:
				return "%s Button" % SWITCH_EXTENDED_GAMEPAD_BUTTON_LABELS[input.button_index]
			SUB_DEVICE_PLAYSTATION3_CONTROLLER, SUB_DEVICE_PLAYSTATION4_CONTROLLER:
				return "%s Button" % PLAYSTATION_3_4_BUTTON_LABELS[input.button_index]
			SUB_DEVICE_PLAYSTATION5_CONTROLLER:
				return "%s Button" % PLAYSTATION_5_BUTTON_LABELS[input.button_index]
			DEVICE_STEAMDECK_CONTROLLER:
				return "%s Button" % STEAMDECK_BUTTON_LABELS[input.button_index]

	elif input is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = input as InputEventJoypadMotion
		match motion.axis:
			JOY_AXIS_LEFT_X:
				return "Left Stick %s" % ("Left" if motion.axis_value < 0 else "Right")
			JOY_AXIS_LEFT_Y:
				return "Left Stick %s" % ("Up" if motion.axis_value < 0 else "Down")
			JOY_AXIS_RIGHT_X:
				return "Right Stick %s" % ("Left" if motion.axis_value < 0 else "Right")
			JOY_AXIS_RIGHT_Y:
				return "Right Stick %s" % ("Up" if motion.axis_value < 0 else "Down")
			JOY_AXIS_TRIGGER_LEFT:
				return "Left Trigger"
			JOY_AXIS_TRIGGER_RIGHT:
				return "Right Trigger"

	return input.as_text()


## Serialize a list of action inputs to string. If actions is empty then it will serialize
## all actions.
func serialize_inputs_for_actions(actions: PackedStringArray = []) -> String:
	if actions == null or actions.is_empty():
		actions = InputMap.get_actions()

	var map: Dictionary = {}
	for action in actions:
		var action_inputs: PackedStringArray = []
		var inputs: Array[InputEvent] = InputMap.action_get_events(action)
		for input in inputs:
			if input is InputEventKey:
				var s: String = get_label_for_input(input)
				var modifiers: Array[String] = []
				if input.alt_pressed:
					modifiers.append("alt")
				if input.shift_pressed:
					modifiers.append("shift")
				if input.ctrl_pressed:
					modifiers.append("ctrl")
				if input.meta_pressed:
					modifiers.append("meta")
				if not modifiers.is_empty():
					s += "|" + ",".join(modifiers)
				action_inputs.append("key:%s" % s)
			elif input is InputEventMouseButton:
				action_inputs.append("mouse:%d" % input.button_index)
			elif input is InputEventJoypadButton:
				action_inputs.append("joypad:%d" % input.button_index)
			elif input is InputEventJoypadMotion:
				action_inputs.append("joypad:%d|%f" % [input.axis, input.axis_value])

		map[action] = ";".join(action_inputs)

	return JSON.stringify({
		version = SERIAL_VERSION,
		map = map
	})


func deserialize_inputs_for_actions(string: String) -> void:
	var data: Dictionary = JSON.parse_string(string)

	# Use legacy deserialization
	if not data.has("version"):
		_deprecated_deserialize_inputs_for_actions(string)
		return

	# Version 1
	for action in data.map.keys():
		InputMap.action_erase_events(action)
		var action_inputs: PackedStringArray = data.map[action].split(";")
		for action_input in action_inputs:
			var bits: PackedStringArray = action_input.split(":")

			# Ignore any empty actions
			if bits.size() < 2: continue

			var input_type: String = bits[0]
			var input_details: String = bits[1]

			match input_type:
				"key":
					var keyboard_input = InputEventKey.new()
					if "|" in input_details:
						var detail_bits = input_details.split("|")
						keyboard_input.keycode = OS.find_keycode_from_string(detail_bits[0])
						detail_bits = detail_bits[1].split(",")
						if detail_bits.has("alt"):
							keyboard_input.alt_pressed = true
						if detail_bits.has("shift"):
							keyboard_input.shift_pressed = true
						if detail_bits.has("ctrl"):
							keyboard_input.ctrl_pressed = true
						if detail_bits.has("meta"):
							keyboard_input.meta_pressed = true
					else:
						keyboard_input.keycode = OS.find_keycode_from_string(input_details)
					InputMap.action_add_event(action, keyboard_input)
					keyboard_input_changed.emit(action, keyboard_input)

				"mouse":
					var mouse_input = InputEventMouseButton.new()
					mouse_input.button_index = int(input_details)
					InputMap.action_add_event(action, mouse_input)
					keyboard_input_changed.emit(action, mouse_input)

				"joypad":
					if "|" in str(input_details):
						var joypad_motion_input = InputEventJoypadMotion.new()
						var joypad_bits = input_details.split("|")
						joypad_motion_input.axis = int(joypad_bits[0])
						joypad_motion_input.axis_value = float(joypad_bits[1])
						InputMap.action_add_event(action, joypad_motion_input)
						joypad_input_changed.emit(action, joypad_motion_input)
					else:
						var joypad_input = InputEventJoypadButton.new()
						joypad_input.button_index = int(input_details)
						InputMap.action_add_event(action, joypad_input)
						joypad_input_changed.emit(action, joypad_input)


# Load inputs from a serialized string. [deprecated]
func _deprecated_deserialize_inputs_for_actions(string: String) -> void:
	var map: Dictionary = JSON.parse_string(string)
	for action in map.keys():
		InputMap.action_erase_events(action)

		for key in map[action]["keyboard"]:
			var keyboard_input = InputEventKey.new()
			if "|" in key:
				var bits = key.split("|")
				keyboard_input.keycode = OS.find_keycode_from_string(bits[0])
				bits = bits[1].split(",")
				if bits.has("alt"):
					keyboard_input.alt_pressed = true
				if bits.has("shift"):
					keyboard_input.shift_pressed = true
				if bits.has("ctrl"):
					keyboard_input.ctrl_pressed = true
				if bits.has("meta"):
					keyboard_input.meta_pressed = true
			else:
				keyboard_input.keycode = OS.find_keycode_from_string(key)
			InputMap.action_add_event(action, keyboard_input)

		for button_index in map[action]["mouse"]:
			var mouse_input = InputEventMouseButton.new()
			mouse_input.button_index = int(button_index)
			InputMap.action_add_event(action, mouse_input)

		for button_index_or_motion in map[action]["joypad"]:
			if "|" in str(button_index_or_motion):
				var joypad_motion_input = InputEventJoypadMotion.new()
				var bits = button_index_or_motion.split("|")
				joypad_motion_input.axis = int(bits[0])
				joypad_motion_input.axis_value = float(bits[1])
				InputMap.action_add_event(action, joypad_motion_input)
			else:
				var joypad_input = InputEventJoypadButton.new()
				joypad_input.button_index = int(button_index_or_motion)
				InputMap.action_add_event(action, joypad_input)


#endregion

#region Keyboard/mouse input


## Get all of the keys/mouse buttons used for an action.
func get_keyboard_inputs_for_action(action: String) -> Array[InputEvent]:
	return InputMap.action_get_events(action).filter(func(event):
		return event is InputEventKey or event is InputEventMouseButton
	)


## Get the first key for an action
func get_keyboard_input_for_action(action: String) -> InputEvent:
	var inputs: Array[InputEvent] = get_keyboard_inputs_for_action(action)
	return null if inputs.is_empty() else inputs[0]


## Set the key used for an action
func set_keyboard_input_for_action(action: String, input: InputEvent, swap_if_taken: bool = true) -> Error:
	return _update_keyboard_input_for_action(action, input, swap_if_taken, null)


## Replace a specific key with another key
func replace_keyboard_input_for_action(action: String, current_input: InputEvent, input: InputEvent, swap_if_taken: bool = true) -> Error:
	return _update_keyboard_input_for_action(action, input, swap_if_taken, current_input)


## Replace a specific key, given its index
func replace_keyboard_input_at_index(action: String, index: int, input: InputEvent, swap_if_taken: bool = true) -> Error:
	var inputs: Array[InputEvent] = get_keyboard_inputs_for_action(action)
	var replacing_input = InputEventKey.new() if (inputs.is_empty() or inputs.size() <= index) else inputs[index]
	return _update_keyboard_input_for_action(action, input, swap_if_taken, replacing_input)


func _update_keyboard_input_for_action(action: String, input: InputEvent, swap_if_taken: bool, replacing_input: InputEvent = null) -> Error:
	if not (input is InputEventKey or input is InputEventMouseButton): return ERR_INVALID_DATA

	var is_valid_keyboard_event = func(event):
		return event is InputEventKey or event is InputEventMouseButton

	return _update_input_for_action(action, input, swap_if_taken, replacing_input, is_valid_keyboard_event, keyboard_input_changed)


#endregion

#region Joypad input


## Get all buttons used for an action
func get_joypad_inputs_for_action(action: String) -> Array[InputEvent]:
	return InputMap.action_get_events(action).filter(func(event):
		return event is InputEventJoypadButton or event is InputEventJoypadMotion
	)


## Get the first button for an action
func get_joypad_input_for_action(action: String) -> InputEvent:
	var buttons: Array[InputEvent] = get_joypad_inputs_for_action(action)
	return null if buttons.is_empty() else buttons[0]


## Set the button for an action
func set_joypad_input_for_action(action: String, input: InputEvent, swap_if_taken: bool = true) -> Error:
	return _update_joypad_input_for_action(action, input, swap_if_taken, null)


## Replace a specific button for an action
func replace_joypad_input_for_action(action: String, current_input: InputEvent, input: InputEventJoypadButton, swap_if_taken: bool = true) -> Error:
	return _update_joypad_input_for_action(action, input, swap_if_taken, current_input)


## Replace a button, given its index
func replace_joypad_input_at_index(action: String, index: int, input: InputEvent, swap_if_taken: bool = true) -> Error:
	var inputs: Array[InputEvent] = get_joypad_inputs_for_action(action)
	var replacing_input
	if inputs.is_empty() or inputs.size() <= index:
		replacing_input = InputEventJoypadButton.new()
		replacing_input.button_index = JOY_BUTTON_INVALID
	else:
		replacing_input = inputs[index]
	return _update_joypad_input_for_action(action, input, swap_if_taken, replacing_input)


## Set the action used for a button
func _update_joypad_input_for_action(action: String, input: InputEvent, swap_if_taken: bool = true, replacing_input: InputEvent = null) -> Error:
	var is_valid_keyboard_event = func(event):
		return event is InputEventJoypadButton or event is InputEventJoypadMotion

	return _update_input_for_action(action, input, swap_if_taken, replacing_input, is_valid_keyboard_event, joypad_input_changed)


func _update_input_for_action(action: String, input: InputEvent, swap_if_taken: bool, replacing_input: InputEvent, check_is_valid: Callable, did_change_signal: Signal) -> Error:
	# Find any action that is already mapped to this input
	var clashing_action = ""
	var clashing_event
	if swap_if_taken:
		for other_action in InputMap.get_actions():
			if other_action == action: continue

			for event in InputMap.action_get_events(other_action):
				if event.is_match(input):
					clashing_action = other_action
					clashing_event = event

	# Find the key based event for the target action
	var action_events: Array[InputEvent] = InputMap.action_get_events(action)
	var is_replacing: bool = false
	for i in range(0, action_events.size()):
		var event: InputEvent = action_events[i]
		if check_is_valid.call(event):
			if replacing_input != null and not event.is_match(replacing_input):
				continue

			# Remap the other event if there is a clashing one
			if clashing_action:
				_update_input_for_action(clashing_action, event, false, clashing_event, check_is_valid, did_change_signal)

			# Replace the event
			action_events[i] = input
			is_replacing = true
			break

	# If we were trying to replace something but didn't find it then just add it to the end
	if not is_replacing:
		action_events.append(input)

	# Apply the changes
	InputMap.action_erase_events(action)
	for event in action_events:
		if event != null:
			InputMap.action_add_event(action, event)

	did_change_signal.emit(action, input)

	return OK


#endregion

#region Rumbling


func rumble_small(target_device: int = 0) -> void:
	Input.start_joy_vibration(target_device, 0.4, 0, 0.1)


func rumble_medium(target_device: int = 0) -> void:
	Input.start_joy_vibration(target_device, 0, 0.7, 0.1)


func rumble_large(target_device: int = 0) -> void:
	Input.start_joy_vibration(target_device, 0, 1, 0.1)


func start_rumble_small(target_device: int = 0) -> void:
	Input.start_joy_vibration(target_device, 0.4, 0, 0)


func start_rumble_medium(target_device: int = 0) -> void:
	Input.start_joy_vibration(target_device, 0, 0.7, 0)


func start_rumble_large(target_device: int = 0) -> void:
	Input.start_joy_vibration(target_device, 0, 1, 0)


func stop_rumble(target_device: int = 0) -> void:
	Input.stop_joy_vibration(target_device)


#endregion
