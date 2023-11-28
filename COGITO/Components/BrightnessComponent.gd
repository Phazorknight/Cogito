extends Node
class_name BrightnessComponent

signal brightness_changed(current_value, max_value)

@export var max_brightness : float = 5
@export var start_brightness : float = 0
var current_brightness : float = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	current_brightness = start_brightness


func add(amount):
	current_brightness += amount
	
	if current_brightness > max_brightness:
		current_brightness = max_brightness
		
	brightness_changed.emit(current_brightness, max_brightness)


func subtract(amount):
	current_brightness -= amount
	
	if current_brightness < 0:
		current_brightness = 0
	
	brightness_changed.emit(current_brightness, max_brightness)
