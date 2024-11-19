extends Node3D

## This gives broad control of wieldable sway strength. 1 = no change in raw sway amount.
@export_range(1,8) var sway_predivision: float = 3
## This gives more granular control of wieldable sway strength.
@export var sway_multiplier : float = .001


func _process(delta: float) -> void:
	position.x = lerp(position.x,0.0,delta*5)
	position.y = lerp(position.y,0.0,delta*5)

func sway(sway_amount: Vector2) -> void:
	position.x += (sway_amount.x/sway_predivision) * sway_multiplier
	position.y += (sway_amount.y/sway_predivision) * sway_multiplier
