class_name CogitoProgressWheel extends Control

@export var bg_color: Color = Color(0,0,0,0.4)
@export var fg_color: Color = Color(1,1,1,0.8)
@export var radius:float = 16
@export var width:float = 4

var current_angle_rad: float
var current_value: float:
	set(value):
		current_value = value
		update_wheel()


func update_wheel():
	var current_angle_deg = current_value * 360
	current_angle_rad = deg_to_rad(current_angle_deg)
	
	if current_angle_rad >= TAU:
		current_angle_rad = TAU
	
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, bg_color, false, width, true)
	draw_arc(Vector2.ZERO, radius, 0, current_angle_rad, 64, fg_color, width, true)
