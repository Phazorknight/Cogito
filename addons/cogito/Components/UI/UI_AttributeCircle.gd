extends Control

@onready var attribute_icon: TextureRect = $VBoxContainer/HBoxContainer/AttributeIcon
@onready var attribute_value: Label = $VBoxContainer/AttributeValue

var assigned_player_attribute : CogitoAttribute

# WHEEL ATTRIBUTES
@export var wheel_center_pos : Vector2 = Vector2(25,25)
@export var bg_color: Color = Color(0,0,0,0.4)
var fg_color: Color
@export var radius:float = 20
@export var width:float = 4
@export var origin_angle_deg: float = -90
var origin_angle_rad: float

var current_angle_rad: float
var current_value: float: # Needs to be between 0.0 and 1.0
	set(value):
		current_value = value
		update_wheel()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	origin_angle_rad = deg_to_rad(origin_angle_deg)


func initiate_attribute_ui(_player_attribute: CogitoAttribute):
	assigned_player_attribute = _player_attribute
	
	#Setting up icon, bar and wheel color
	attribute_icon.texture = assigned_player_attribute.attribute_icon
	attribute_value.text = str(int(assigned_player_attribute.value_current))
	fg_color = assigned_player_attribute.attribute_color

	#Setting wheel to current attribute value
	current_value = assigned_player_attribute.value_current / assigned_player_attribute.value_max
	
	_player_attribute.attribute_changed.connect(on_attribute_changed)
	
	
func on_attribute_changed(_attribute_name:String,_value_current:float,_value_max:float,_has_increased:bool):
	current_value = assigned_player_attribute.value_current / assigned_player_attribute.value_max
	attribute_value.text = str(int(_value_current))





func update_wheel():
	var current_angle_deg = current_value * 360 + origin_angle_deg
	current_angle_rad = deg_to_rad(current_angle_deg)
	
	#if current_angle_rad >= TAU:
		#current_angle_rad = TAU
	
	queue_redraw()

func _draw() -> void:
	draw_circle(wheel_center_pos, radius, bg_color, false, width, true)
	draw_arc(wheel_center_pos, radius, origin_angle_rad, current_angle_rad, 64, fg_color, width, true)
