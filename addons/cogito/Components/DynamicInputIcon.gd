extends Sprite2D
class_name DynamicInputIcon

## Name of action as called in the Input Map
@export var action_name : String
## Spritesheet of gamepad icons, this is currently applied to all gamepads (no matter if PS, Xbox, Switch, generic)
@export var gamepad_icons : Texture2D
## Spritesheet of keyboard icons
@export var keyboard_icons : Texture2D
## Spritesheet for Xbox gamepad icons
@export var xbox_icons : Texture2D
## Spritesheet for Playstation gamepad icons
@export var playstation_icons : Texture2D
## Spritesheet for Steam Deck gamepad icons
@export var steam_deck_icons : Texture2D
## Spritesheet for Nintendo Switch gamepad icons
@export var switch_icons : Texture2D

enum InputIconType{
	DYNAMIC,
	DYNAMIC_GAMEPAD,
	KBM,
	XBOX,
	PS5,
	SWITCH,
}

@export var input_icon_type: InputIconType

var device
var device_index


func _ready():
	InputHelper.device_changed.connect(update_device)
	update_device(InputHelper.device,InputHelper.device_index)
	
	InputHelper.keyboard_input_changed.connect(check_for_input_change)
	InputHelper.joypad_input_changed.connect(check_for_input_change)


func update_device(_device, _device_index):
	device = _device
	device_index = _device_index
	# Rudimentary Steam Deck detection, treating it as an Xbox Controller
	if _is_steam_deck():
		device = "steam_deck"
	
	update_input_icon.call_deferred() #Calling this deferred as there's been Input Icons that exist before the cfg is loaded.
	
	
func update_input_icon():
	CogitoGlobals.debug_log(true,"DynamicInputIcon.gd","update_input_icon() called. current device = " + str(device))
	match input_icon_type:
		InputIconType.DYNAMIC:
			update_input_icon_dynamic()
		InputIconType.DYNAMIC_GAMEPAD:
			update_gamepad_icon()
		InputIconType.KBM:
			update_icon_kbm()
		InputIconType.XBOX:
			update_gamepad_icon(xbox_icons)
		InputIconType.PS5:
			update_gamepad_icon(playstation_icons)
		InputIconType.SWITCH:
			update_gamepad_icon(switch_icons)


func check_for_input_change(_action, _input):
	if _action == action_name:
		update_input_icon()


func update_input_icon_dynamic():
	match device:
		"steam_deck":
			update_gamepad_icon(steam_deck_icons)
		InputHelper.DEVICE_KEYBOARD:
			update_icon_kbm()
		InputHelper.DEVICE_XBOX_CONTROLLER:
			update_gamepad_icon(xbox_icons)
		InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
			update_gamepad_icon(playstation_icons)
		InputHelper.DEVICE_SWITCH_CONTROLLER:
			update_gamepad_icon(switch_icons)
		"generic":
			update_gamepad_icon(xbox_icons)


func update_gamepad_icon(icon_textures:Texture2D = gamepad_icons):
	hframes = 12
	vframes = 12
	set_texture(icon_textures)
	
	var joypad_input = InputHelper.get_joypad_input_for_action(action_name)
	if joypad_input is InputEventJoypadButton:
		frame = joypad_input.button_index
	elif joypad_input is InputEventJoypadMotion:
		frame = gamepad_motion_to_frame_index(joypad_input)
	else:
		CogitoGlobals.debug_log(true, "DynamicInputIcon.gd", "Action " + action_name + ": No gamepad input map assigned.")
		frame = 140
		return

func update_icon_kbm(): # Sets the bound action to keyboard and mouse icon
	set_texture(keyboard_icons)
	
	var keyboard_input = InputHelper.get_keyboard_input_for_action(action_name)
	if keyboard_input is InputEventKey:
		if keycode_to_frame_index(OS.get_keycode_string(keyboard_input.keycode)) == -1:
			return
		frame = keycode_to_frame_index(OS.get_keycode_string(keyboard_input.keycode))
	elif keyboard_input is InputEventMouseButton:
		if keyboard_input.get_button_index() == MOUSE_BUTTON_RIGHT:
			frame = keycode_to_frame_index("Mouse Right")
		if keyboard_input.get_button_index() == MOUSE_BUTTON_LEFT:
			frame = keycode_to_frame_index("Mouse Left")
		if keyboard_input.get_button_index() == MOUSE_BUTTON_MIDDLE:
			frame = keycode_to_frame_index("Mouse Middle")
		if keyboard_input.get_button_index() == MOUSE_BUTTON_WHEEL_UP:
			frame = keycode_to_frame_index("Mouse Wheel Up")
		if keyboard_input.get_button_index() == MOUSE_BUTTON_WHEEL_DOWN:
			frame = keycode_to_frame_index("Mouse Wheel Down")
		
		
	else:
		CogitoGlobals.debug_log(true, "DynamicInputIcon.gd", "Action " + action_name + ": No primary keyboard/mouse input map assigned.")
		frame = 0
		return


func _is_steam_deck() -> bool:
	if RenderingServer.get_rendering_device() == null:
		print("DynamicInputIcon: ISSUE: No rendering device detected.")
		return false
	if RenderingServer.get_rendering_device().get_device_name().contains("RADV VANGOGH") \
	or OS.get_processor_name().contains("AMD CUSTOM APU 0405"):
		return true
	else:
		return false


func gamepad_motion_to_frame_index(joypad_input_motion: InputEventJoypadMotion):
	match joypad_input_motion.axis:
		0: # LEFT STICK H AXIS
			if joypad_input_motion.axis_value > 0: # LEFT STICK RIGHT
				return 38
			else: # LEFT STICK LEFT
				return 37
		1: # LEFT STICK V AXIS
			if joypad_input_motion.axis_value < 0: # LEFT STICK UP
				return 39
			else: # LEFT STICK DOWN
				return 40
		2: # RIGHT STICK H AXIS
			if joypad_input_motion.axis_value > 0: # RIGHT STICK RIGHT
				return 49
			else: # RIGHT STICK LEFT
				return 50
		3: # RIGHT STICK V AXIS
			if joypad_input_motion.axis_value < 0: # RIGHT STICK UP
				return 51
			else: # RIGHT STICK DOWN
				return 52 
		5: # RIGHT TRIGGER
			return 34
		4: # LEFT TRIGGER
			return 35
		null:
			return 10
		_:
			return -1


func keycode_to_frame_index(key_code_string: String) -> int:
	match key_code_string:
		null:
			return 0
		"Mouse Left":
			return 108
		"Mouse Right":
			return 109
		"Mouse Middle":
			return 110
		"Mouse Wheel Up":
			return 113
		"Mouse Wheel Down":
			return 114
		"0":
			return 1
		"1":
			return 2
		"2":
			return 3
		"3":
			return 4
		"4":
			return 5
		"5":
			return 6
		"6":
			return 7
		"7":
			return 8
		"8":
			return 9
		"9":
			return 10
		"A":
			return 12
		"B":
			return 13
		"C":
			return 14
		"D":
			return 15
		"E":
			return 16
		"F":
			return 17
		"G":
			return 18
		"H":
			return 19
		"I":
			return 20
		"J":
			return 21
		"K":
			return 22
		"L":
			return 23
		"M":
			return 24
		"N":
			return 25
		"O":
			return 26
		"P":
			return 27
		"Q":
			return 28
		"R":
			return 29
		"S":
			return 30
		"T":
			return 31
		"U":
			return 32
		"V":
			return 33
		"W":
			return 34
		"X":
			return 35
		"Y":
			return 36
		"Z":
			return 37
		"~":
			return 38
		"'":
			return 39
		"<":
			return 40
		">":
			return 41
		"[":
			return 42
		"]":
			return 43
		".":
			return 44
		":":
			return 45
		",":
			return 46
		";":
			return 47
		"=":
			return 48
		"+":
			return 49
		"-":
			return 50
		"^":
			return 51
		"\"":
			return 52
		"?":
			return 53
		"!":
			return 54
		"*":
			return 55
		"/":
			return 56
		"\\":
			return 57
		"Escape":
			return 60
		"Ctrl":
			return 61
		"Alt":
			return 62
		"Space":
			return 63
		"Tab":
			return 64
		"Enter":
			return 65
		"Shift":
			return 66
		
		_:
			return -1
