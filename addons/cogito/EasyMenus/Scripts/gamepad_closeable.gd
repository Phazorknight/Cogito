extends Node

var parent_option_button : OptionButton

func _ready():
	parent_option_button = get_parent()
	# Need to connect to the input from the popups viewport
	parent_option_button.get_popup().window_input.connect(_input)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		parent_option_button.get_popup().visible = false
