extends Node3D
class_name HitboxComponent

@export var health_attribute : CogitoHealthAttribute

func _ready():
	if health_attribute:
		health_attribute.death.connect(on_death)

func damage(damage_amount:float):
	if health_attribute:
		health_attribute.subtract(damage_amount)

func on_death():
	pass
