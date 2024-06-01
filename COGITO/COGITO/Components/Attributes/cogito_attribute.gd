@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoAttribute.svg")
extends Node
class_name CogitoAttribute

## Triggered whenever any of the attribute values changes.
signal attribute_changed(attribute_name:String, value_current:float, value_max:float, has_increased:bool)
## Triggered when this attribute current value reaches 0.
signal attribute_reached_zero(attribute_name:String, value_current:float, value_max:float)

## Used for scripting / condition checks, so should not include spaces and be all lowercase.
@export var attribute_name : String
## Used for UI
@export var attribute_display_name : String
## Used for UI / HUD.
@export var attribute_color : Color
## Used for UI  /HUD.
@export var attribute_icon : Texture2D
## Maximum value of this attribute. Can be changed/saved during runtime.
@export var value_max : float
## Value this attribute starts with per default.
@export var value_start : float
## Use this for when you want an attribute value to be unchangeable but still use signals etc. Can also be turned on/off at runtime.
@export var is_locked : bool = false
## Use this when you don't want an attribute's current value to not be saved.
@export var dont_save_current_value : bool = false

var value_current : float

# Used when loading/setting an attribute
func set_attribute(_value_current:float, _value_max:float):
	value_current = _value_current
	value_max = _value_max
	attribute_changed.emit(attribute_name,value_current,value_max,true)


func add(amount):
	if is_locked:
		attribute_changed.emit(attribute_name,value_current,value_max,true)
		return
		
	value_current += amount
	
	if value_current > value_max:
		value_current = value_max
	attribute_changed.emit(attribute_name,value_current,value_max,true)


func subtract(amount):
	if is_locked:
		attribute_changed.emit(attribute_name,value_current,value_max,false)
		return
		
	value_current -= amount
	
	if value_current <= 0:
		value_current = 0
		attribute_reached_zero.emit(attribute_name,value_current,value_max)
		
	attribute_changed.emit(attribute_name,value_current,value_max,false)
