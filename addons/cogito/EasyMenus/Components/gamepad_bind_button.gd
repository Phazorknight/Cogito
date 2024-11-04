extends Button
class_name GamepadBindButton

@export var action: String:
	set(value):
		action = value
		update_icon()

@onready var gamepad_input_icon: Sprite2D = $MarginContainer/DynamicInputIcon

func _init():
	toggle_mode = true
	theme_type_variation = "RemapButton"


func _ready():
	set_process_unhandled_input(false)
	update_icon()


func _toggled(button_pressed):
	set_process_unhandled_input(button_pressed)
	if button_pressed:
		text = "..."
		gamepad_input_icon.visible = false
		release_focus()
	else:
		update_icon()
		grab_focus()


func _unhandled_input(event):
	if event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
		return
	
	if event is InputEventJoypadButton:
		if event.pressed:
			InputHelper.set_joypad_input_for_action(action,event,true)
			get_viewport().set_input_as_handled()
			text = ""
			gamepad_input_icon.visible = true
			update_icon()
			button_pressed = false


func update_icon():
	#text = "%s" % InputMap.action_get_events(action)[0].as_text()
	gamepad_input_icon.action_name = action
	gamepad_input_icon.update_input_icon()
