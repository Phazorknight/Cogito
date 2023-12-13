extends Node
class_name HealthComponent

signal health_changed(current_value, max_value)
signal death()

@export var max_health : float = 5
@export var start_health : float
@export var no_sanity_damage : float
var current_health : float

# Called when the node enters the scene tree for the first time.
func _ready():
	current_health = start_health

func add(amount):
	current_health += amount
	
	if current_health > max_health:
		current_health = max_health
	emit_signal("health_changed", current_health, max_health)
		
func subtract(amount):
	current_health -= amount
	
	if current_health < 0:
		current_health = 0
		emit_signal("death")
	
	emit_signal("health_changed", current_health, max_health)
