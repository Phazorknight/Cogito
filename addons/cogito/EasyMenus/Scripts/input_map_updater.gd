extends Node

func _ready():
	if !InputMap.has_action("menu"):
		InputMap.add_action("menu")
	
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_ESCAPE
	if !InputMap.action_has_event("menu", key_event):
		InputMap.action_add_event("menu", key_event)
	
	var gamepad_event = InputEventJoypadButton.new()
	gamepad_event.button_index = JOY_BUTTON_START
	if !InputMap.action_has_event("menu", gamepad_event):
		InputMap.action_add_event("menu", gamepad_event)
	
	gamepad_event = InputEventJoypadButton.new()
	gamepad_event.button_index = JOY_BUTTON_A
	if !InputMap.action_has_event("ui_accept", gamepad_event):
		InputMap.action_add_event("ui_accept", gamepad_event)

	gamepad_event = InputEventJoypadButton.new()
	gamepad_event.button_index = JOY_BUTTON_B
	if !InputMap.action_has_event("ui_cancel", gamepad_event):
		InputMap.action_add_event("ui_cancel", gamepad_event)
