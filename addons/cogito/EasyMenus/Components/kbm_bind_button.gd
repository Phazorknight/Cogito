extends Button
class_name KbmBindButton

@export var action: String:
	set(value):
		action = value
		update_icon()

@onready var kbm_input_icon: Sprite2D = $MarginContainer/DynamicInputIcon

var is_remapping: bool = false

func _init():
	toggle_mode = true
	theme_type_variation = "RemapButton"


func _ready():
	set_process_unhandled_input(false)
	update_icon()


func _toggled(button_pressed):
	is_remapping = button_pressed
	if button_pressed:
		text = "..."
		kbm_input_icon.visible = false
		release_focus()
	else:
		update_icon()
		grab_focus()


func _input(event):
	if !is_remapping:
		return
	
	if event is InputEventJoypadMotion:
		return
	
	if event is InputEventKey || ( event is InputEventMouseButton && event.pressed):
		InputHelper.set_keyboard_input_for_action(action,event,false)
		text = ""
		kbm_input_icon.visible = true
		update_icon()
		
		is_remapping = false
		button_pressed = false
		
	accept_event()


func update_icon():
	#text = "%s" % InputMap.action_get_events(action)[0].as_text()
	kbm_input_icon.action_name = action
	kbm_input_icon.update_input_icon()
