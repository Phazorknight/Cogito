extends Node

var echo_event = null

@onready var echo_timer : Timer = $EchoTimer
@onready var waiting_timer : Timer = $WaitingTimer

func _input(event):
	if event is InputEventJoypadButton:
		echo_event = event
		if event.pressed and (event.is_action("ui_up") or event.is_action("ui_down") or event.is_action("ui_left") or event.is_action("ui_right")):
			waiting_timer.start()
		else:
			waiting_timer.stop()
			echo_timer.stop()

func _on_echo_timer_timeout():
	Input.parse_input_event(echo_event)

func _on_waiting_timer_timeout():
	echo_timer.start()
