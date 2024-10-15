extends Area3D

@export var sanity_recovery_rate : int = 2
@export var sanity_recovery_max : int

func _on_body_entered(body):
	if body.is_in_group("Player") :
		print("Player entered safezone.")
		body.brightness_component.add(1)
		

func _on_body_exited(body):
	if body.is_in_group("Player") :
		print("Player left dangerzone.")
		body.brightness_component.subtract(1)
