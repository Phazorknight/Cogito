extends Node
class_name HitboxComponent

@export var health_attribute : CogitoHealthAttribute

func _ready() -> void:
	if get_parent() is CogitoObject:
		if !get_parent().damage_received.is_connected(damage):
			get_parent().damage_received.connect(damage)
	else:
		print("HitboxComponent: Parent ", get_parent().name, " isn't CogitoObject.")

func damage(damage_amount:float):
	if health_attribute:
		health_attribute.subtract(damage_amount)
