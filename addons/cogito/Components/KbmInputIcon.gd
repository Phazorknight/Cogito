extends Sprite2D

## Name of action as called in the Input Map
@export var action_name : String
## Spritesheet of keyboard icons
@export var keyboard_icons : Texture2D

var device
var device_index


func _ready():
	update_input_icon()


func update_input_icon():
	set_texture(keyboard_icons)
	var keyboard_input = InputHelper.get_keyboard_input_for_action(action_name)
	if keyboard_input is InputEventKey:
		#print("DynamicInputIcon: Action=", action_name, ". Physical keycode=", keyboard_input.get_physical_keycode(), ". Keycode string=", OS.get_keycode_string(keyboard_input.get_physical_keycode()))
		frame = keycode_to_sprite_frame_index(OS.get_keycode_string(keyboard_input.get_physical_keycode()))
	elif keyboard_input is InputEventMouseButton:
		if keyboard_input.get_button_index() == 2:
			frame = keycode_to_sprite_frame_index("Mouse Right")
		if keyboard_input.get_button_index() == 1:
			frame = keycode_to_sprite_frame_index("Mouse Left")
	else:
		print("DynamicInputIcon: Action=", action_name, ". No primary keyboard/mouse input map assigned.")
		frame = 0
		return



func keycode_to_sprite_frame_index(key_code_string: String) -> int:
	match key_code_string:
		null:
			return 0
		"Mouse Left":
			return 28
		"Mouse Right":
			return 29
		"A":
			return 1
		"B":
			return 2
		"C":
			return 3
		"D":
			return 4
		"E":
			return 5
		"F":
			return 6
		"G":
			return 7
		"H":
			return 8
		"I":
			return 9
		"J":
			return 10
		"K":
			return 11
		"L":
			return 12
		"M":
			return 13
		"N":
			return 14
		"O":
			return 15
		"P":
			return 16
		"Q":
			return 17
		"R":
			return 18
		"S":
			return 19
		"T":
			return 20
		"U":
			return 21
		"V":
			return 22
		"W":
			return 23
		"X":
			return 24
		"Y":
			return 25
		"Z":
			return 26
		"Space":
			return 40
		"Tab":
			return 41
		"Escape":
			return 42
		"Shift":
			return 43
		"Ctrl":
			return 44
		"Alt":
			return 45
		"0":
			return 30
		"1":
			return 31
		"2":
			return 32
		"3":
			return 33
		"4":
			return 34
		"5":
			return 35
		"6":
			return 36
		"7":
			return 37
		"8":
			return 38
		"9":
			return 39
		_:
			return -1
