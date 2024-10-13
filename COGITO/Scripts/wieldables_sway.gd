extends Node3D

@export var sway_multiplier : float = .0008

func _process(delta: float) -> void:
	position.x = lerp(position.x,0.0,delta*5)
	position.y = lerp(position.y,0.0,delta*5)

func sway(sway_amount: Vector2) -> void:
	position.x += sway_amount.x * sway_multiplier
	position.y += sway_amount.y * sway_multiplier
