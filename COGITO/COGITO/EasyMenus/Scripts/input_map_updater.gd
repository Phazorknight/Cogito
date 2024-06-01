extends Node

func _ready():
	if !InputMap.has_action("pause"):
		InputMap.add_action("pause")
	
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_ESCAPE
	if !InputMap.action_has_event("pause", key_event):
		InputMap.action_add_event("pause", key_event)
	
	var gamepad_event = InputEventJoypadButton.new()
	gamepad_event.button_index = JOY_BUTTON_START
	if !InputMap.action_has_event("pause", gamepad_event):
		InputMap.action_add_event("pause", gamepad_event)
	
	gamepad_event = InputEventJoypadButton.new()
	gamepad_event.button_index = JOY_BUTTON_A
	if !InputMap.action_has_event("ui_accept", gamepad_event):
		InputMap.action_add_event("ui_accept", gamepad_event)

	gamepad_event = InputEventJoypadButton.new()
	gamepad_event.button_index = JOY_BUTTON_B
	if !InputMap.action_has_event("ui_cancel", gamepad_event):
		InputMap.action_add_event("ui_cancel", gamepad_event)