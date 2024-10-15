extends Node

## Sets if parent lightzone should respond to CogitoSwitch "switched" signal.
@export var switchable: bool = true

## Connect to CogitoSwitch.gd "switched" signal to enable
func _on_switched(is_on: bool):
	if switchable:
		var lightzone: Area3D = get_parent()
		if lightzone:
			lightzone.set_monitoring(is_on)
