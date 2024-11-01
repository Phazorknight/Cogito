extends Sprite2D

## Name of action as called in the Input Map
@export var action_name : String
## Spritesheet of gamepad icons
@export var gamepad_icons : Texture2D

var device
var device_index


func _ready():
	update_input_icon()


func update_input_icon():
	set_texture(gamepad_icons)
	var joypad_input = InputHelper.get_joypad_input_for_action(action_name)
	if joypad_input == null:
		frame = 0
	
	if joypad_input is InputEventJoypadButton:
		#print("DynamicInputIcon: Action=", action_name, ". Joypad btn=", joypad_input.button_index)
		frame = joypad_input.button_index
		
	elif joypad_input is InputEventJoypadMotion:
		#print("DynamicInputIcon: Action=", action_name, ". Joypad motion=", joypad_motion.axis)
		if joypad_input.axis == 0 or joypad_input.axis == 1:
			frame = 8
		if joypad_input.axis == 2 or joypad_input.axis == 3:
			frame = 9
		
		if joypad_input.axis == 5:
			frame = 18 #Sets icon to RT
		if joypad_input.axis == 4:
			frame = 17 #Sets icon to LT
