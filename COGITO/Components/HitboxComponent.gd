extends Node3D
class_name HitboxComponent

@export var health_component : HealthComponent

func _ready():
	if health_component:
		health_component.death.connect(on_death)

func damage(damage_amount:float):
	if health_component:
		health_component.subtract(damage_amount)

func on_death():
	pass
