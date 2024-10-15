extends OptionButton

# Called when the node enters the scene tree for the first time.
func _ready():
	get_popup().connect("window_input", propagate_input)
	pass # Replace with function body.


func propagate_input(event):
	if MenuTemplateManager.ControllerEchoInputGenerator:
		MenuTemplateManager.ControllerEchoInputGenerator._input(event)
